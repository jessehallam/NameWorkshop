using System.ComponentModel.DataAnnotations.Schema;

namespace NameWorkshop.Data.Entities
{
	[Table("external_identity", Schema = "membership")]
	public class ExternalIdentity
	{
		/// <summary>
		/// Primary key.
		/// </summary>
		public int Id { get; set; }

		/// <summary>
		/// The internal identity of the user.
		/// </summary>
		public virtual InternalIdentity Identity { get; set; }

		/// <summary>
		/// The provider name.
		/// </summary>
		public string Provider { get; set; }

		/// <summary>
		/// The provider user id.
		/// </summary>
		public string ProviderUserId { get; set; }
	}
}