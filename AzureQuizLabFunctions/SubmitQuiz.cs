using System.Text.Json;
using Azure.Storage.Queues;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AzureQuizLabFunctions
{
    public class SubmitQuiz
    {
        private readonly ILogger<SubmitQuiz> _logger;
        private readonly QueueClient _queueClient;

        public SubmitQuiz(ILogger<SubmitQuiz> logger)
        {
            _logger = logger;
            var connectionString = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
            _queueClient = new QueueClient(connectionString, "quiz-queue", new QueueClientOptions
            {
                MessageEncoding = QueueMessageEncoding.Base64
            });
            _queueClient.CreateIfNotExists();
        }

        [Function("SubmitQuiz")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("SubmitQuiz function triggered");

            // send message
            _queueClient.SendMessage(JsonSerializer.Serialize(new
            {
                userId = "123",
                quizId = "456",
                score = 80,
                submittedAt = DateTime.UtcNow
            }));

            _logger.LogInformation("Quiz submitted!");
            return new OkObjectResult("Quiz submitted!");
        }
    }
}
