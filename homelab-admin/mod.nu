# Nushell helper for homelab-admin skill

# Checks basic network interfaces and active listener ports
export def inspect-homelab-network [] {
    let listeners = (try {
        ^ss -tulpn | lines | skip 1 | parse -r '(?P<netid>\S+)\s+(?P<state>\S+)\s+(?P<recv>\S+)\s+(?P<send>\S+)\s+(?P<local>\S+)\s+(?P<peer>\S+)'
    } catch { [] })
    
    let routes = (try { ^ip -br addr | lines } catch { [] })
    
    {
        total_listeners: ($listeners | length),
        routes_summary: ($routes | length)
    }
}
