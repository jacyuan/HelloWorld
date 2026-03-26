using System;
using System.Collections.Generic;

namespace HelloWorld.Models;

public partial class Log
{
    public int Id { get; set; }

    public DateTime LogDate { get; set; }

    public string Message { get; set; } = null!;
}
