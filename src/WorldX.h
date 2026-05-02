#pragma once

#include "ll/api/mod/NativeMod.h"

namespace worldx {

class WorldX {
public:
    static WorldX& getInstance();

    // Provides access to the logger, data directory, etc.
    [[nodiscard]] ll::mod::NativeMod& getSelf() const { return mSelf; }

    [[nodiscard]] bool load();
    [[nodiscard]] bool unload() const;

private:
    // The constructor now initializes mSelf.
    WorldX() : mSelf(*ll::mod::NativeMod::current()) {}

    void registerCommands();

    ll::mod::NativeMod& mSelf;
};

} // namespace worldx
