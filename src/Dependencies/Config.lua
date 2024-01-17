-- Configuration

return {
    -- Controls if when an object is out of activation distance / fov if its bones should be sent back to their rest location.
    RESET_TRANSFORM_ON_SKIP = true,
    -- Wouldn't recommend enabling, controls if we should wait after each collider setup.
    YIELD_ON_COLLIDER_GATHER = false,
    -- Allows for debug tools out of studio
    ALLOW_LIVE_GAME_DEBUG = false,
    -- Maximum distance for field of view checks, if an object is out of this distance its skipped regardless of activation distance.
    FAR_PLANE = 500,
    -- Debug info in output, can lag the game.
    LOG_VERBOSE = false
}
