namespace SternenBuergerUnitySpike.Core
{
    public sealed class CharacterProfile
    {
        public CharacterProfile(
            string id,
            string displayName,
            string callsign,
            Role preferredRole,
            int leadership,
            int shooting,
            int movement,
            int medicine,
            int tech,
            string trait)
        {
            Id = id;
            DisplayName = displayName;
            Callsign = callsign;
            PreferredRole = preferredRole;
            Leadership = leadership;
            Shooting = shooting;
            Movement = movement;
            Medicine = medicine;
            Tech = tech;
            Trait = trait;
        }

        public string Id { get; private set; }
        public string DisplayName { get; private set; }
        public string Callsign { get; private set; }
        public Role PreferredRole { get; private set; }
        public int Leadership { get; private set; }
        public int Shooting { get; private set; }
        public int Movement { get; private set; }
        public int Medicine { get; private set; }
        public int Tech { get; private set; }
        public string Trait { get; private set; }

        public string ShortLine
        {
            get
            {
                return string.Format(
                    "{0} [{1}] L{2} S{3} M{4} Med{5} {6}",
                    Callsign,
                    PreferredRole,
                    Leadership,
                    Shooting,
                    Movement,
                    Medicine,
                    Trait);
            }
        }
    }
}
