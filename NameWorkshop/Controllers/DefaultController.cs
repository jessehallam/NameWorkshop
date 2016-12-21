using System.Web.Mvc;

namespace NameWorkshop.Controllers
{
    public class DefaultController : Controller
    {
	    public ActionResult Index()
	    {
		    return View();
	    }
    }
}