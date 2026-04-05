Config = {}
config = Config

Config.Damage = 35.0 -- Schadenswert (1000 - Health), ab dem Aussteigen blockiert wird.

Config.BreakEngineOnCriticalDamage = true -- Soll der Motor kaputt gehen, wenn der Schaden erreicht ist?

Config.CrashDelta = 80.0 -- Mindest-Abfall der Health zwischen zwei Messungen, um einen Crash zu erkennen.

Config.CrashCooldownMs = 60 -- Cooldown zwischen zwei E-CALLs pro Spieler.

Config.Firefighteronline = 3 -- Wie viele Feuerwehrleute online sein müssen, damit das script aktiv wird. (Standard: 3)

Config.NotifyBlockedExit = true -- Benachrichtigung anzeigen, wenn Aussteigen blockiert ist.

Config.NotifyBlockedExitCooldownMs = 5000 -- Cooldown zwischen zwei Aussteigen-Block-Notifies.

Config.NotifyBlockedExitTitle = 'E-CALL' -- Titel der v42-notify Meldung.

Config.NotifyBlockedExitMessage = 'Du kannst nicht aussteigen. Warte auf die Feuerwehr.' -- Text der Meldung.