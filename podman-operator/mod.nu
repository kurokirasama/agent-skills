# Nushell helper for podman-operator skill

# Checks if podman is available and returns system container counts
export def get-podman-status [] {
    let has_podman = ((which podman | length) > 0)
    if not $has_podman {
        return { installed: false, containers: 0, images: 0 }
    }
    
    let containers = (try { podman ps -a --format json | from json | length } catch { 0 })
    let images = (try { podman images --format json | from json | length } catch { 0 })
    
    {
        installed: true,
        containers: $containers,
        images: $images
    }
}
