-- Configuration

return {
    VERSION = "0.3.0",
    -- Controls if when an object is out of activation distance / fov if its bones should be sent back to their rest location.
    RESET_TRANSFORM_ON_SKIP = true,
    -- Wouldn't recommend enabling, controls if we should wait after each collider setup.
    YIELD_ON_COLLIDER_GATHER = false,
    -- Allows for debug tools out of studio
    ALLOW_LIVE_GAME_DEBUG = false,
    -- Maximum distance for field of view checks, if an object is out of this distance its skipped regardless of activation distance.
    FAR_PLANE = 500,
    -- Debug info in output, can lag the game.
    LOG_VERBOSE = false,
    -- Enable or disable the startup print
    STARTUP_PRINT_ENABLED = true,
    -- Overlay config, not meant for end users
    DEBUG_OVERLAY_ENABLED = true, -- enable or disable when debug is enabled
    DEBUG_OVERLAY_TREE = true, -- enable tree debug
    DEBUG_OVERLAY_TREE_INFO = false,
    DEBUG_OVERLAY_TREE_OBJECTS = false,
    DEBUG_OVERLAY_TREE_NUMERICS = false,
    DEBUG_OVERLAY_TREE_OFFSET = 0, -- how offset into the roots we should be
    DEBUG_OVERLAY_MAX_TREES = 5, -- -1 for no max
    DEBUG_OVERLAY_BONE = true, -- enable bone debug info
    DEBUG_OVERLAY_BONE_OFFSET = 0, -- how offset into the bone tree we should be
    DEBUG_OVERLAY_MAX_BONES = -1, -- -1 for no max
    DEBUG_OVERLAY_BONE_INFO = false,
    DEBUG_OVERLAY_BONE_NUMERICS = false,
    DEBUG_OVERLAY_BONE_CONSTRAIN = false,
    DEBUG_OVERLAY_BONE_WELD = true,
}
