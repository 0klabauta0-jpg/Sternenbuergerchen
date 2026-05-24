namespace SternenBuergerUnitySpike.Core
{
    public sealed class DropshipState
    {
        public DropshipState(string id, string displayName, int capacity)
        {
            Id = id;
            DisplayName = displayName;
            Capacity = capacity;
            Status = DropshipStatus.Available;
        }

        public string Id { get; private set; }
        public string DisplayName { get; private set; }
        public int Capacity { get; private set; }
        public DropshipStatus Status { get; set; }
        public string AssignedFireteamId { get; set; }
        public string ActiveMissionId { get; set; }
        public float FlightProgress { get; set; }

        public bool IsAvailable
        {
            get { return Status == DropshipStatus.Available || Status == DropshipStatus.Assigned; }
        }
    }
}
