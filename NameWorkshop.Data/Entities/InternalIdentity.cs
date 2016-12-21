using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace NameWorkshop.Data.Entities
{
	[Table("internal_identity", Schema = "membership")]
	public class InternalIdentity
	{
		/// <summary>
		/// A collection of provider identities belonging to the user.
		/// </summary>
		public virtual ICollection<ExternalIdentity> ExternalIdentities { get; set; }
		
		/// <summary>
		/// A collection of files belonging to the user.
		/// </summary>
		public virtual ICollection<File> Files { get; set; } 

		/// <summary>
		/// Primary key.
		/// </summary>
		public int Id { get; set; }

		/// <summary>
		/// The username.
		/// </summary>
		public string Name { get; set; }
	}
}