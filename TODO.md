fish skills should check for level before casting
check these:
void HandleSu(const std::vector<std::string>& packetSplitted)
{
    if (packetSplitted.size() < 16) return;

    int casterID = std::atoi(packetSplitted[2].c_str());
    int skillID = std::atoi(packetSplitted[5].c_str());

    if (casterID == botManager->getPlayerID())
    {
        botManager->setOnCooldown(skillID);
    }
}

void HandleEff(const std::vector<std::string>& packetSplitted)
{
    if (packetSplitted.size() < 4) return;
    if (packetSplitted[1] != "1") return;
    if (packetSplitted[2] != std::to_string(botManager->getPlayerID())) return;
    if (packetSplitted[3] != "8") return;

    botManager->resetSkillCD();
}

void HandleSay(const std::vector<std::string>& packetSplitted)
{
    if (!botManager->isRunning()) return;
    if (packetSplitted.size() < 6) return;
    if (packetSplitted[1] != "1") return;
    if (packetSplitted[2] != std::to_string(botManager->getPlayerID())) return;
    if (packetSplitted[3] != "10") return;
    if (packetSplitted[4] != "fish") return;
    if (packetSplitted[5] != "data") return;

    Sleep(DELAY);
    botManager->startFishing();
}

toggle between dps and fishing broken

dps mode for ic/ac.
auto join ic and ac correct.

auto join does not work. maybe small timer and prevent duplicate send?

ascobas point levels
raid mode somehow working?

GUI? possibilities. win32?

iceflower gathering bot?
