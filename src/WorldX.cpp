#include "WorldX.h"

// LL API
#include "ll/api/command/CommandHandle.h"
#include "ll/api/command/CommandRegistrar.h"
#include "ll/api/command/runtime/RuntimeOverload.h"
#include "ll/api/mod/RegisterHelper.h"
#include "ll/api/service/Bedrock.h"

// MC API
#include "mc/server/commands/CommandOrigin.h"
#include "mc/server/commands/CommandOutput.h"
#include "mc/server/commands/CommandPermissionLevel.h"
#include "mc/world/actor/player/Player.h"
#include "mc/world/actor/Actor.h"
#include "mc/server/ServerInstance.h"
#include "mc/deps/core/math/Vec3.h"

namespace worldx {

WorldX& WorldX::getInstance() {
    static WorldX instance;
    return instance;
}

void WorldX::registerCommands() {
    auto& registrar = ll::command::CommandRegistrar::getServerInstance();
    auto& handle = registrar.getOrCreateCommand("world", "World management commands", CommandPermissionLevel::GameDirectors);

    handle.runtimeOverload()
        .text("setspawn") // NOLINT(spellcheck)
        .execute([](CommandOrigin const& origin, CommandOutput& output, ll::command::RuntimeCommand const& command) {
            Actor* actor = origin.getEntity();
            if (!actor || !actor->isPlayer()) {
                output.error("This command can only be run by a player.");
                return;
            }

            auto* player = reinterpret_cast<Player*>(actor);
            Vec3 const newSpawnPos = player->getPosition();

            std::string posX = std::to_string(static_cast<int>(newSpawnPos.x));
            std::string posY = std::to_string(static_cast<int>(newSpawnPos.y));
            std::string posZ = std::to_string(static_cast<int>(newSpawnPos.z));

            output.success("Target spawn point identified at: " + posX + ", " + posY + ", " + posZ + ". Execute '/setworldspawn' to apply it globally."); // NOLINT(spellcheck)
            (void)command; // Prevent unused variable warning
        });

    // Placeholder for future commands once APIs are available
    handle.runtimeOverload()
        .text("create")
        .required("worldName", ll::command::ParamKind::String)
        .execute([](CommandOrigin const& origin, CommandOutput& output, ll::command::RuntimeCommand const& command) {
            output.error("World creation is not yet available. Waiting for API access approval.");
        });
}

bool WorldX::load() {
    getSelf().getLogger().info("WorldX Mod Loaded!");
    registerCommands();
    return true;
}

bool WorldX::unload() const {
    getSelf().getLogger().info("WorldX Mod Unloaded!");
    return true;
}

} // namespace worldx

LL_REGISTER_MOD(worldx::WorldX, worldx::WorldX::getInstance());
