---
name: fastapi-templates
description: Create production-ready FastAPI projects with async patterns, dependency injection, RORO architecture, Pydantic v2 validation, and comprehensive error handling. Use when building new FastAPI applications or setting up backend API projects.
---

# FastAPI Project Templates

Production-ready FastAPI project structures with async patterns, dependency injection, middleware, and best practices for building high-performance APIs.

## When to Use This Skill

- Starting new FastAPI projects from scratch
- Implementing async REST APIs with Python
- Building high-performance web services and microservices
- Creating async applications with PostgreSQL, MongoDB
- Setting up API projects with proper structure and testing

## Core Concepts

### 1. Project Structure

**Recommended Layout:**

```
app/
├── api/                    # API routes
│   ├── v1/
│   │   ├── endpoints/
│   │   │   ├── users.py
│   │   │   ├── auth.py
│   │   │   └── items.py
│   │   └── router.py
│   └── dependencies.py     # Shared dependencies
├── core/                   # Core configuration
│   ├── config.py
│   ├── security.py
│   └── database.py
├── models/                 # Database models
│   ├── user.py
│   └── item.py
├── schemas/                # Pydantic schemas
│   ├── user.py
│   └── item.py
├── services/               # Business logic
│   ├── user_service.py
│   └── auth_service.py
├── repositories/           # Data access
│   ├── user_repository.py
│   └── item_repository.py
└── main.py                 # Application entry
```

### 2. Dependency Injection

FastAPI's built-in DI system using `Depends`:

- Database session management
- Authentication/authorization
- Shared business logic
- Configuration injection

### 3. Async Patterns

Proper async/await usage:

- Async route handlers
- Async database operations
- Async background tasks
- Async middleware


## FastAPI Engineering Principles

### Python & FastAPI Standards
- Favor functional, declarative modularization with explicit exports and lowercase `snake_case` naming for modules/routers (e.g., `routers/user_routes.py`).
- Follow the **RORO (Receive an Object, Return an Object)** pattern using typed **Pydantic v2** `BaseModel` schemas rather than raw dictionaries.
- Use descriptive auxiliary-verb names for boolean flags/checks (e.g., `is_active`, `has_permission`).
- Use `def` for pure/synchronous helpers and `async def` for asynchronous I/O routes and service calls; avoid blocking I/O on the event loop.
- Prefer FastAPI `lifespan` context managers over deprecated startup/shutdown events, and leverage middleware for logging, timing, and CORS.
- Core Stack: **FastAPI**, **Pydantic v2**, **SQLAlchemy 2.0**, and **asyncpg / aiosqlite / aiomysql**.

### Error Handling & Guard Clauses
- Validate preconditions and edge cases at function entry points using early returns (`if ...: return/raise`) rather than nested `if/else` blocks; keep the happy path last.
- Raise structured `HTTPException` responses for expected client errors; log full tracebacks internally and return generic, non-sensitive error details to callers.

### Performance Optimization
- Use async database drivers and connection pooling across all I/O paths.
- Cache frequent reads via Redis or bounded in-memory stores; paginate or lazy-load large collections and optimize Pydantic serialization (`model_dump`, `from_attributes=True`).

## Progressive Disclosure & Testing

- Complete templates for app entrypoint/config/async DB, generic CRUD repository, service layer, versioned API routers, JWT/OAuth2 dependencies, and `httpx.AsyncClient` test fixtures: [references/project-patterns.md](references/project-patterns.md)
- Activate `python-testing-patterns` alongside `fastapi-templates` for comprehensive `pytest`, fixture isolation, mocking, and coverage gates.
