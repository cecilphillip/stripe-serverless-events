using AzStripeEvents.Serverless.Models;
using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Stripe;
using Stripe.Checkout;

namespace AzStripeEvents.Serverless;

public class StripeHookFunction(ILogger<StripeHookFunction> logger, IConfiguration config)
{
    [Function(nameof(StripeEventsHook))]
    public async Task<StripeEventsHookResponse> StripeEventsHook(
        [HttpTrigger(AuthorizationLevel.Function, "POST", Route = "stripe/events")]
        HttpRequest req
    )
    {
        logger.LogInformation("stripe webhook received");
        try
        {
            var payload = await new StreamReader(req.Body).ReadToEndAsync();
            var webhookSecret = config.GetValue<string>("STRIPE_WEBHOOK_SECRET");
            var stripeEvent = EventUtility.ConstructEvent(
                payload, req.Headers["Stripe-Signature"], webhookSecret);

            // Do something fun
            switch (stripeEvent.Type)
            {
                case Events.CheckoutSessionCompleted when stripeEvent.Data.Object is Session
                {
                    PaymentStatus: "paid"
                } session:
                    
                    return new StripeEventsHookResponse()
                    {
                        HttpResponse = new OkResult(),
                        Message = new FulfillOrder(session.Id)
                    };
            }
        }
        catch (StripeException ex)
        {
            const string message = "stripe exception handling webhook";
            logger.LogError(ex, message);

            var resp = new BadRequestObjectResult(new ProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Instance = req.Path,
                Detail = message
            });

            return new StripeEventsHookResponse()
            {
                HttpResponse = resp
            };
        }
        
        return new StripeEventsHookResponse()
        {
            HttpResponse = new OkResult()
        };
    }
    
    [Function(nameof(CheckoutQueueProcessor))]
    public void CheckoutQueueProcessor(
        [ServiceBusTrigger("checkout.completed", Connection = "ServiceBusConnection", IsBatched = false)] ServiceBusReceivedMessage message)
    {
        logger.LogInformation("Received message from checkout.completed queue {MessageId}", message.MessageId);
        var orderPayload = message.Body.ToObjectFromJson<FulfillOrder>();
    }
}