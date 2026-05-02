#include "WorldX.h"

#include "ll/api/mod/RegisterHelper.h"

namespace worldx {

// This is the correct singleton pattern based on your example.
WorldX& WorldX::getInstance() {
    static WorldX instance;
    return instance;
}

bool WorldX::load() {
    // Use getSelf() to access the logger.
    getSelf().getLogger().info("WorldX Mod Loaded!");
    return true;
}

bool WorldX::unload() {
    getSelf().getLogger().info("WorldX Mod Unloaded!");
    return true;
}

} // namespace worldx

// This is the correct registration macro.
LL_REGISTER_MOD(worldx::WorldX, worldx::WorldX::getInstance());
