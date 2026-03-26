using System.Diagnostics;
using HelloWorld.Models;
using Microsoft.AspNetCore.Mvc;

namespace HelloWorld.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly IConfiguration _configuration;
        private readonly QuizDbContext _context;

        public HomeController(
            QuizDbContext context,
            ILogger<HomeController> logger,
            IConfiguration configuration
        )
        {
            _logger = logger;
            _configuration = configuration;
            _context = context;
        }

        public IActionResult Index()
        {
            var maintenanceMode = _configuration.GetValue<bool>("MaintenanceMode");
            var quizCount = _context.Quizzes.Count();
            var questionCount = _context.Questions.Count();
            var model = new HomeViewModel
            {
                MaintenanceMode = maintenanceMode,
                QuizCount = quizCount,
                QuestionCount = questionCount,
            };

            return View(model);
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(
                new ErrorViewModel
                {
                    RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier,
                }
            );
        }
    }
}
