using Azure.Storage.Queues.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System;

namespace AzureQuizLabFunctions
{
    public class ProcessQuiz
    {
        private readonly ILogger<ProcessQuiz> _logger;

        public ProcessQuiz(ILogger<ProcessQuiz> logger)
        {
            _logger = logger;
        }

        [Function(nameof(ProcessQuiz))]
        public void Run([QueueTrigger("quiz-queue", Connection = "AzureWebJobsStorage")] QueueMessage message)
        {
            var connectionString = Environment.GetEnvironmentVariable("SqlConnectionString");
            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();
                var cmd = new SqlCommand("INSERT INTO Logs (Message, LogDate) VALUES (@msg, GETDATE())", conn);
                cmd.Parameters.AddWithValue("@msg", message.MessageText);
                cmd.ExecuteNonQuery();
            }

            _logger.LogInformation("Ecriture en base effectuée");
        }
    }
}
