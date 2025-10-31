# Agent Instructions for the Simple-Config Repository

This document outlines the critical lessons learned from the initial, and often problematic, setup of this repository. Adherence to these guidelines is mandatory for any future modifications to prevent a recurrence of the issues that caused significant user frustration and system breakage.

## Core Directive: Do No Harm

**Under no circumstances should any script or tool overwrite a user's personal configuration files.**

The `install.sh` script in this repository was originally designed to copy configuration files into the user's `~/.config/` directory. This is a destructive action that will wipe out the user's personal settings, including their wallpaper, keybindings, and other customizations.

**Future modifications must adhere to one of the following principles:**

1.  **Non-Destructive Installation:** Any installer script must be **non-destructive**. It should check for the existence of configuration files and, if they exist, modify them in place rather than replacing them. For example, instead of overwriting `~/.config/niri/config.kdl`, a script should read the file and append or modify the necessary sections.

2.  **User Confirmation:** If a destructive action is absolutely unavoidable, the script must first obtain explicit, interactive confirmation from the user. It must clearly state what it is about to do and what the consequences will be.

## User Preferences are Paramount

**Never assume user preferences, especially for keybindings.**

During the initial setup, the agent made repeated, incorrect assumptions about the user's preferred keybindings for the application launcher and other tools. This caused significant frustration.

**Future modifications must adhere to the following principles:**

1.  **Always Ask:** Before assigning or changing any keybinding, you must ask the user what key combination they would prefer.
2.  **Respect Existing Bindings:** Be aware that common key combinations (like `Super+D`) may already be in use. Always confirm with the user before using them.

## Tool-Specific Limitations

The tools used in this repository (Waybar, EWW) have specific limitations that are not immediately obvious. Failure to account for these will result in crashes.

*   **Waybar CSS:** Waybar uses a GTK-based CSS renderer that does **not** support modern CSS features. Unsupported properties like `transform`, `box-shadow`, and at-rules like `@media` will cause the entire stylesheet to fail to load, which will crash Waybar. All CSS must be compatible with this limited renderer.
*   **EWW Variable Definitions:** All variables in an EWW configuration (`.yuck` file) must be defined before they can be used or updated.
    *   For static variables, use `defvar`.
    *   For variables that are periodically updated by a script, use `defpoll`.
    *   A variable **cannot** be defined with both `defvar` and `defpoll`.
    *   Variables that are expected to be JSON objects must be defined as such (e.g., `(defvar battery '{"capacity": 0, "status": "Unknown"}')`).
*   **EWW Widget Names:** The EWW configuration is sensitive to syntax errors. Using a non-existent widget name (e.g., `center-box` instead of `box`) will cause the entire configuration to fail to load.

## Consistency is Key

**All parts of the configuration must be consistent with each other.**

Several bugs were caused by inconsistencies between different parts of the project:
*   An EWW bar was removed from the `eww.yuck` configuration, but the `install.sh` script still tried to open it.
*   A Waybar module was removed from the list of active modules, but its configuration block was left in the file, causing confusion.
*   An EWW widget expected a variable in a JSON format, but the script that was supposed to provide the data was sending it as a simple string.

Any change to one part of the system must be reflected in all other parts that depend on it.
