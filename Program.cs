var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/info", () => Results.Ok(new
{
	hostname = Environment.GetEnvironmentVariable("HOSTNAME") ?? Environment.MachineName,
	timestamp = DateTimeOffset.UtcNow
}));

app.Run();
