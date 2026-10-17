// Sends one unmatched pointer button RELEASE through zwlr_virtual_pointer_v1.
// river leaves move-view/resize-view only when its seat-wide pressed_count
// reaches zero, and a normal click is net-zero, so clearing a stranded button
// needs a release with no press. ydotool cannot do this: it injects via uinput
// and libinput drops a release for a button that device never pressed.
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include "wlr-virtual-pointer-unstable-v1-client-protocol.h"

static struct zwlr_virtual_pointer_manager_v1 *manager;

static void global(void *data, struct wl_registry *registry, uint32_t name,
                   const char *interface, uint32_t version) {
    if (!strcmp(interface, zwlr_virtual_pointer_manager_v1_interface.name))
        manager = wl_registry_bind(
            registry, name, &zwlr_virtual_pointer_manager_v1_interface, 1);
}

static void global_remove(void *data, struct wl_registry *registry,
                          uint32_t name) {}

static const struct wl_registry_listener registry_listener = {global,
                                                              global_remove};

static void usage(const char *self) {
    fprintf(stderr,
            "usage: %s [button]\n"
            "  button: evdev code in 0x100-0x15f; default 0x110 (BTN_LEFT)\n"
            "Only run when a button is known to be held: river asserts\n"
            "pressed_count > 0 and the whole session dies otherwise.\n",
            self);
}

// A bogus argument must abort before connecting -- silently becoming button 0
// sends a release that can kill the compositor.
static int parse_button(const char *arg, uint32_t *out) {
    char *end;
    errno = 0;
    unsigned long value = strtoul(arg, &end, 0);
    if (errno != 0 || end == arg || *end != '\0')
        return -1;
    if (value < 0x100 || value > 0x15f)
        return -1;
    *out = (uint32_t)value;
    return 0;
}

int main(int argc, char **argv) {
    uint32_t button = 0x110;

    if (argc == 2 && (!strcmp(argv[1], "-h") || !strcmp(argv[1], "--help"))) {
        usage(argv[0]);
        return 0;
    }
    if (argc > 2) {
        usage(argv[0]);
        return 2;
    }
    if (argc == 2 && parse_button(argv[1], &button) != 0) {
        fprintf(stderr, "invalid button '%s'\n\n", argv[1]);
        usage(argv[0]);
        return 2;
    }

    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "cannot connect to a wayland display\n");
        return 1;
    }

    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip(display);

    if (!manager) {
        fprintf(stderr, "compositor has no zwlr_virtual_pointer_manager_v1\n");
        return 1;
    }

    struct zwlr_virtual_pointer_v1 *pointer =
        zwlr_virtual_pointer_manager_v1_create_virtual_pointer(manager, NULL);
    zwlr_virtual_pointer_v1_button(pointer, 0, button, 0);
    zwlr_virtual_pointer_v1_frame(pointer);
    wl_display_flush(display);
    wl_display_roundtrip(display);

    fprintf(stderr, "released button 0x%x\n", button);
    return 0;
}
