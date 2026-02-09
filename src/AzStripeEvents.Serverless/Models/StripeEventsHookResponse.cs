using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;

namespace AzStripeEvents.Serverless.Models;

public class StripeEventsHookResponse
{
    [ServiceBusOutput("checkout.completed", Connection = "ServiceBusConnection")]
    public FulfillOrder? Message { get; set; }

    public IActionResult HttpResponse { get; set; }
}

public record FulfillOrder(string SessionId);