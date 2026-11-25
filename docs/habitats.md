# Habitat guide

Every Trailomon belongs to one of six habitats. A habitat is more than a type in the
damage chart: it decides how a creature fights, which statuses it uses, how its stats
lean and what it looks like. Use this guide when designing a new Trailomon, so that any
creature's habitat can be guessed from its kit alone.

The in-game version of each habitat's one-line identity lives in `CombatData.HABITATS`
and shows in the habitat tooltips.

## The six habitats at a glance

| Habitat | Core identity | Owns these keywords | Hits hard | Hits softly | Takes extra from |
|---|---|---|---|---|---|
| Forest | Endurance: outlast the enemy | Shield, Taunt, Thorns | Swamp | River | River |
| River | Flow: keep things moving | Heal, Cleanse, Drain, Wash away | Forest | Snow | Snow |
| Swamp | Rot: wear foes down | Poison, Weaken | Mountain | Forest | Forest |
| Mountain | Weight: slow, crushing blows | Pierce, Stagger, Finisher | Jungle | Swamp | Swamp |
| Snow | Cold and speed | Slow, Haste, Brittle | River | Jungle | Jungle |
| Jungle | Reach: strike from anywhere | Reach, Dodge, hits behind | Snow | Mountain | Mountain |

A creature's kit must use at least one keyword its own habitat owns, and never the
signature keyword of another habitat. (A Snow creature never poisons; a Swamp creature
never heals its allies.)

## Forest: Endurance

Forest creatures win by refusing to fall. They punish attackers, grow bark and pull
hits onto themselves.

- **Basic attacks:** hits that scale with Defense as well as Attack, hits that give
  Shield, and hits that get stronger while shielded.
- **Passives:** thorns that hit back when struck, bark Shield every few attacks.
- **Ultimates:** big Shields for itself and adjacent allies, Taunt, a strike that turns
  the damage into Shield.
- **Stats:** high health (380 to 520), high Defense (30 to 45), low to middling Attack
  (24 to 30), slow (2.0 to 2.3 seconds per attack).
- **Usual roles:** Guard, Bruiser. A Forest Striker is a shielded skirmisher.
- **Look:** bark plating, moss, briars, antlers and roots. Deep greens and browns.
  Heavy, rooted, old.
- **Trail work:** strength, guarding, steadiness.
- **Team bonus (Deep Roots):** Forest allies gain Defense.
- **Never:** poison, speed boosts, healing.
- **Current creatures:** Brambleback (thorns guard), Coilhusk (bark bruiser),
  Thornfang (shielded skirmisher), the Hollow Stag (boss: shields its whole pack).
- **Archetypes:** Thornwarden (thorns, punish attackers) or Barkguard (Shields and Taunt).

## River: Flow

River creatures keep the fight moving their way: wounds close, poison washes off and
enemy Shields get stripped away.

- **Basic attacks:** a hit that also heals the most hurt ally, a hit that washes away
  the target's Shield first.
- **Passives:** heals that cleanse poison and Weaken, life drain on damage dealt.
- **Ultimates:** a heal for the whole team, a dive past the front row onto the weakest
  enemy.
- **Stats:** middling to low health (260 to 340), low Defense (10 to 18), middling
  Attack (26 to 32), middling speed (1.7 to 1.9).
- **Usual roles:** Healer, Striker (a diver).
- **Look:** fins, gills, reeds, ink and smooth scales. Blues and teals. Sleek and wet.
- **Trail work:** swimming, scouting.
- **Team bonus (Flowing):** River heals and Shields are stronger.
- **Never:** thorns, heavy armor, poison.
- **Current creatures:** Reedwake (healer), Inkhoot (diver that strips Shields).
- **Archetypes:** Mender (healing and cleansing) or Riptide (drain, wash away, dive).

## Swamp: Rot

Swamp creatures make every second hurt. Poison ticks, armor rots, and their heavy
hitters feast on whatever is already rotting.

- **Basic attacks:** hits that poison, hits that Weaken (lower Defense).
- **Passives:** poison that also Weakens, bonus damage against poisoned or weakened foes.
- **Ultimates:** poison the whole enemy team, a heavy strike that poisons.
- **Stats:** middling health (300 to 420), middling Defense (18 to 28), middling Attack
  (26 to 30), middling speed (1.9 to 2.1).
- **Usual roles:** Support, Bruiser.
- **Look:** glowing lamps and lures, mud, gills, rot and reeds. Murky greens and
  purples. Damp and drooping.
- **Trail work:** light, healing (herbs), swimming.
- **Team bonus (Murk):** Swamp poisons last longer.
- **Never:** healing allies, Shields.
- **Current creatures:** Mirelamp (poison support), Gillhorn (bruiser that Weakens).
- **Archetypes:** Plaguebearer (spread poison) or Rotter (Weaken, then hit the rotted).

## Mountain: Weight

Mountain creatures are slow, and every hit lands like a rockfall. They break through
armor, knock attacks off rhythm and finish off the wounded.

- **Basic attacks:** hits that Stagger (knock the target's attack bar back), hits that
  deal more to badly hurt foes, hits that ignore part of Defense.
- **Passives:** extra Defense when hurt, ignoring half of the target's Defense.
- **Ultimates:** one huge strike that pierces, a sweep across a whole row.
- **Stats:** high health (380 to 440), middling to high Defense (22 to 40), high Attack
  (27 to 38), slow (2.0 to 2.4).
- **Usual roles:** Guard, Striker, Bruiser.
- **Look:** stone plates, horns, crystals and cairns. Slate greys and ochres. Massive.
- **Trail work:** clearing, strength.
- **Team bonus (Bedrock):** Mountain allies gain Attack.
- **Never:** speed boosts, poison, healing.
- **Current creatures:** Scythelk (finisher striker), Cairnram (staggering guard).
- **Archetypes:** Breaker (pierce and finishers) or Bulwark (Stagger and armor).

## Snow: Cold and speed

Snow creatures are quick and fragile. They slow the enemy, speed up their friends and
strike again and again.

- **Basic attacks:** hits that Slow, quick double strikes.
- **Passives:** attacking faster while any foe is slowed, bonus damage to slowed
  (brittle) foes.
- **Ultimates:** Haste for the whole team, a burst that slows a cluster of enemies.
- **Stats:** low health (260 to 300), low Defense (12 to 18), middling Attack (25 to
  28), fast (1.4 to 1.7).
- **Usual roles:** Support, Striker.
- **Look:** white fur, frost, ice shells and long ears or legs. Pale blues and whites.
  Small and quick.
- **Trail work:** cold hardiness, scouting.
- **Team bonus (Flurry):** Snow allies attack faster.
- **Never:** Shields, poison, slow heavy hits.
- **Current creatures:** Rimehare (haste support), Frostsnip (double-sting striker).
- **Archetypes:** Frostbinder (Slow and brittle) or Gale (Haste and fast hits).

## Jungle: Reach

Jungle creatures ignore the usual lines. They reach the second row, strike the creature
behind the target and slip out of the way of blows.

- **Basic attacks:** attacks that name the second row (reach), hits that set up a Dodge.
- **Passives:** bonus damage to the second row, basic attacks that also hit the enemy
  behind the target.
- **Ultimates:** hitting the whole second row, gusts that hit a row and protect itself.
- **Stats:** low to middling health (240 to 360), Defense from low to high, middling
  Attack (24 to 28), fast to middling (1.6 to 2.0).
- **Usual roles:** Striker, Guard (an evasive one).
- **Look:** vines, tails, wings, bright plates and canopy leaves. Vivid greens with
  orange or gold. Agile.
- **Trail work:** scouting, clearing, guarding.
- **Team bonus (Canopy):** Jungle creatures deal more to the second row.
- **Never:** thorns, poison, healing.
- **Current creatures:** Lianetail (back-row striker), Plateflit (dodging guard).
- **Archetypes:** Canopy (reach the second row) or Skirmisher (Dodge and hits behind).

## Targeting rules every kit must respect

- A basic attack hits the nearest row that still has creatures: the whole front row must
  fall before an ordinary attack can touch the second row.
- Only a move that names a row, such as Vine Whip (reach) or Dive (weakest enemy
  anywhere), can go over the front. A Taunt still pulls reach attacks.
- Moves that say "adjacent" or "behind" can splash onto the second row, because they say so.

## Recipe for a new Trailomon

1. Pick a habitat and a role.
2. Set stats inside the habitat's ranges, nudged by role (a Guard gets the top of the
   health and Defense ranges).
3. **Basic attack:** never a plain hit. Give it one habitat twist from the list above.
4. **Passive:** it should change or react to basic attacks, or to the habitat's own keyword.
5. **Ultimate:** a bigger, rarer version of the same identity, worth about 1.5 to 2.2
   basic attacks of damage or an effect the whole team feels. It should fire about every
   9 to 15 seconds.
6. Check the keyword rule: at least one of its own habitat's, none of another
   habitat's signatures.
7. Plan its two archetypes from the habitat's pair, for level-ups.
8. Give it a look from the habitat's palette and shapes, and one or two trail jobs.
9. Make it a hybrid of real animals, in look and name, like Coilhusk, Inkhoot, Plateflit,
   Gillhorn, Scythelk or Frostsnip (Conner's rule for all 300).
10. Write it into its habitat's roster file in `src/core/data/roster/` (species entry, kit and
    its three moves). Dust-biome Trailomon go in `blight.gd` / `glow.gd` with
    `"biome": "Blight"` or `"Glow"`. An evolution line names its next form with
    `"evolves_to"` (a list when it branches). The encounter tables pick it up on their own.
11. Run the tests: `tests/core/test_roster.gd` checks the keyword rule (Balance.SIGNATURE),
    the power budget for its rarity and its speed. `tools/sim/roster_sim.gd` prints a round
    robin against its own rarity.
