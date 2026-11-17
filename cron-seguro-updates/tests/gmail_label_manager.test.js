const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

// Import helpers (will fail in RED phase until implemented)
const {
  ensureLabelExists,
  applyLabelAndMarkRead,
  searchUnprocessedMessages,
  getMessageDetails
} = require('../scripts/gmail_label_manager.js');

describe('Gmail Label Manager', () => {
  describe('ensureLabelExists', () => {
    it('returns existing label ID if label already exists', async () => {
      const mockClient = {
        request: async (opts) => {
          assert.equal(opts.method, 'GET');
          assert.match(opts.url, /gmail\/v1\/users\/me\/labels/);
          return {
            data: {
              labels: [
                { id: 'Label_123', name: 'seguro/procesado' },
                { id: 'INBOX', name: 'INBOX' }
              ]
            }
          };
        }
      };

      const labelId = await ensureLabelExists(mockClient, 'seguro/procesado');
      assert.equal(labelId, 'Label_123');
    });

    it('uses DEFAULT_LABEL_NAME ("seguro/procesado") by default', async () => {
      const mockClient = {
        request: async () => ({
          data: { labels: [{ id: 'Label_default', name: 'seguro/procesado' }] }
        })
      };
      const labelId = await ensureLabelExists(mockClient);
      assert.equal(labelId, 'Label_default');
    });

    it('creates label when it does not exist and returns new label ID', async () => {
      let created = false;
      const mockClient = {
        request: async (opts) => {
          if (opts.method === 'GET') {
            return { data: { labels: [{ id: 'INBOX', name: 'INBOX' }] } };
          }
          if (opts.method === 'POST') {
            assert.match(opts.url, /gmail\/v1\/users\/me\/labels/);
            assert.deepEqual(opts.data, {
              name: 'seguro/procesado',
              labelListVisibility: 'labelShow',
              messageListVisibility: 'show'
            });
            created = true;
            return { data: { id: 'Label_new_456', name: 'seguro/procesado' } };
          }
        }
      };

      const labelId = await ensureLabelExists(mockClient, 'seguro/procesado');
      assert.equal(created, true);
      assert.equal(labelId, 'Label_new_456');
    });
  });

  describe('applyLabelAndMarkRead', () => {
    it('sends POST to modify message labels with addLabelIds and removeLabelIds', async () => {
      let modified = false;
      const mockClient = {
        request: async (opts) => {
          assert.equal(opts.method, 'POST');
          assert.match(opts.url, /gmail\/v1\/users\/me\/messages\/msg_123\/modify/);
          assert.deepEqual(opts.data, {
            addLabelIds: ['Label_seguro'],
            removeLabelIds: ['UNREAD']
          });
          modified = true;
          return { data: { id: 'msg_123' } };
        }
      };

      const result = await applyLabelAndMarkRead(mockClient, 'msg_123', 'Label_seguro');
      assert.equal(modified, true);
      assert.equal(result.success, true);
    });
  });

  describe('searchUnprocessedMessages', () => {
    it('calls Gmail messages endpoint with encoded query', async () => {
      const mockClient = {
        request: async (opts) => {
          assert.equal(opts.method, 'GET');
          assert.match(opts.url, /gmail\/v1\/users\/me\/messages\?q=/);
          return {
            data: {
              messages: [{ id: 'msg_1' }, { id: 'msg_2' }]
            }
          };
        }
      };

      const messages = await searchUnprocessedMessages(mockClient, 'from:insurance');
      assert.equal(messages.length, 2);
      assert.equal(messages[0].id, 'msg_1');
    });

    it('returns empty array when messages field is absent', async () => {
      const mockClient = {
        request: async () => ({ data: {} })
      };
      const messages = await searchUnprocessedMessages(mockClient, 'from:insurance');
      assert.deepEqual(messages, []);
    });

    it('follows nextPageToken and returns messages from every page', async () => {
      const calls = [];
      const mockClient = {
        request: async (opts) => {
          calls.push(opts.url);
          if (calls.length === 1) {
            return { data: { messages: [{ id: 'msg_1' }], nextPageToken: 'tok_page_2' } };
          }
          return { data: { messages: [{ id: 'msg_2' }] } };
        }
      };

      const messages = await searchUnprocessedMessages(mockClient, 'from:insurance');
      assert.deepEqual(messages.map((m) => m.id), ['msg_1', 'msg_2']);
      assert.equal(calls.length, 2);
      assert.match(calls[1], /pageToken=tok_page_2/);
    });

    it('continues pagination when a page has no messages but carries a token', async () => {
      const calls = [];
      const mockClient = {
        request: async () => {
          calls.push(1);
          if (calls.length === 1) {
            return { data: { messages: [], nextPageToken: 'tok_next' } };
          }
          return { data: { messages: [{ id: 'msg_3' }] } };
        }
      };

      const messages = await searchUnprocessedMessages(mockClient, 'from:insurance');
      assert.deepEqual(messages.map((m) => m.id), ['msg_3']);
      assert.equal(calls.length, 2);
    });

    it('deduplicates message ids repeated across pages', async () => {
      let page = 0;
      const mockClient = {
        request: async () => {
          page++;
          if (page === 1) {
            return { data: { messages: [{ id: 'dup' }], nextPageToken: 't' } };
          }
          return { data: { messages: [{ id: 'dup' }, { id: 'new' }] } };
        }
      };

      const messages = await searchUnprocessedMessages(mockClient, 'from:insurance');
      assert.deepEqual(messages.map((m) => m.id), ['dup', 'new']);
    });

    it('requests maxResults=100 and never adds inbox/unread restrictions', async () => {
      const calls = [];
      const mockClient = {
        request: async (opts) => {
          calls.push(opts.url);
          return { data: { messages: [] } };
        }
      };

      await searchUnprocessedMessages(mockClient);
      assert.equal(calls.length, 1);
      assert.match(calls[0], /maxResults=100/);
      assert.match(decodeURIComponent(calls[0]), /-label:insurance\/procesado/);
      assert.doesNotMatch(decodeURIComponent(calls[0]), /in:inbox/);
      assert.doesNotMatch(decodeURIComponent(calls[0]), /is:unread/);
    });
  });

  describe('getMessageDetails', () => {
    it('calls GET message details with format=full', async () => {
      const mockClient = {
        request: async (opts) => {
          assert.equal(opts.method, 'GET');
          assert.match(opts.url, /gmail\/v1\/users\/me\/messages\/msg_999\?format=full/);
          return {
            data: {
              id: 'msg_999',
              threadId: 'th_999',
              payload: { headers: [{ name: 'Subject', value: 'Test' }] }
            }
          };
        }
      };

      const details = await getMessageDetails(mockClient, 'msg_999');
      assert.equal(details.id, 'msg_999');
      assert.equal(details.payload.headers[0].value, 'Test');
    });
  });
});
