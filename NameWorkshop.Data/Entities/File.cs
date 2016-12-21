using System.ComponentModel.DataAnnotations.Schema;

namespace NameWorkshop.Data.Entities
{
	[Table("file", Schema = "fsys")]
	public class File
	{
		public string Content { get; set; }

		/// <summary>
		/// Primary key.
		/// </summary>
		public int Id { get; set; }

		/// <summary>
		/// The file name.
		/// </summary>
		public string FileName { get; set; }

		/// <summary>
		/// The user which owns the file.
		/// </summary>
		public virtual InternalIdentity Owner { get; set; }

		/// <summary>
		/// The file path.
		/// </summary>
		public string Path { get; set; }
	}
}