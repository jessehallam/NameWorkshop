using System.Data.Entity;
using NameWorkshop.Data.Entities;

namespace NameWorkshop.Data
{
	public class NwContext : DbContext
	{
		public IDbSet<ExternalIdentity> ExternalIdentities { get; set; }
		public IDbSet<File> Files { get; set; }
		public IDbSet<InternalIdentity> InternalIdentities { get; set; }

		public NwContext(): this("Default") { }
		public NwContext(string nameOrConnectionString) : base(nameOrConnectionString) { }
	}
}