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

toggle between dps and fishing broken.
reset recv que? and log it

dps mode for ic/ac.
auto join ic and ac correct.
try: sl 0
packet

auto join does not work. maybe small timer and prevent duplicate send?

ascobas point levels
raid mode somehow working?

GUI? possibilities. win32?

iceflower gathering bot?
