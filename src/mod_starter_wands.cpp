#include "ScriptMgr.h"
#include "Player.h"

namespace {
    constexpr uint32 WAND_ITEM_ID = 5235;

    class GivePlayerWandOnCreateScript final : public PlayerScript {
        public:
            GivePlayerWandOnCreateScript() : PlayerScript("StarterWandsScript") {

            }

            void OnPlayerFirstLogin(
                Player* player
            ) override {
                if (player->HasSkill(SKILL_WANDS)) {
                    player->EquipNewItem(SLOT_RANGED, WAND_ITEM_ID, true);
                }
            }
    };
}

void MOD_STARTER_WANDS_INIT() {
    new GivePlayerWandOnCreateScript();
}
