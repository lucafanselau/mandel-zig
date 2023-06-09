const std = @import("std");

const fmt = std.fmt;
const zigimg = @import("zigimg");

fn random_u8() u8 {
    return std.crypto.random.intRangeAtMost(u8, 0, 255);
}

const Pixel = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn zero() Pixel {
        return Pixel {
            .r = 0,
            .g = 0,
            .b = 0
        };
    }

    pub fn rand() Pixel {
        return Pixel {
            .r = random_u8(),
            .g = random_u8(),
            .b = random_u8()
        };
    }


    pub fn write(self: Pixel, writer: anytype) !void {
        try fmt.format(writer, "{} {} {} ", .{self.r, self.g, self.b});
    }
};

fn write_file(comptime width: u32, comptime height: u32, pixels: [height][width]Pixel) !void {

    const file = try std.fs.cwd().createFile("./image.ppm", .{ .read = false });
    defer file.close();

    try file.writer().print("P3 {} {} 255\n", .{ width, height });

    for (pixels) |row| {
        for (row) |pixel| {
            try pixel.write(file.writer());
        }
        try file.writer().print("\n", .{});
    }

}

// mandelbrot algorithm
    const config = .{
         .xmin = -2.0,
 .xmax = 0.6,
 
 .ymin  = -1.5,
 .ymax  = 1.5,

 .MAX_ITERS = 200
    };

fn complex_norm(c: *std.math.Complex(f64)) f64 {
    return c.re * c.re + c.im * c.im;
}

fn mandelbrot_kernel(complex: std.math.Complex(f64)) usize {
    var z = std.math.Complex(f64).init(complex.re, complex.im);
    
        //std.debug.print("{} {} {}\n", .{z.re, z.im, complex_norm(&z)});
    for (0..config.MAX_ITERS) |i| {
        z = z.mul(z).add(complex);
        if (complex_norm(&z) > 4) {
            return i;
        }
    }
    return config.MAX_ITERS;
}

fn mandelbrot_pixel(complex: std.math.Complex(f64)) Pixel {
    const i = mandelbrot_kernel(complex);
    const grayscale = @floatToInt(u8, 255.0 * @intToFloat(f64, i) / @intToFloat(f64, config.MAX_ITERS));

    // std.debug.print("{} {} \n", .{grayscale, complex});

    return Pixel {
        .r = grayscale,
        .g = grayscale,
        .b = grayscale
    };
}

fn build_img(comptime width: u32, comptime height: u32) !void {

    var pixels = [1][width]Pixel{[_]Pixel{ Pixel.zero() } ** width} ** height;

    

const dy = (config.ymax - config.ymin) / @intToFloat(f64, height);
const dx = (config.xmax - config.xmin) / @intToFloat(f64, width);


    for (0..height) |j| {
        var y = config.ymin + (@intToFloat(f64, j) * dy);
        for (0..width) |i| {
            var x =  config.xmin + (@intToFloat(f64, i) * dx);
 //std.debug.print("{} {} {} {} {} {}\n", .{i, j, x, y, dy, dx});
            pixels[j][i] = mandelbrot_pixel(std.math.Complex(f64).init(x, y));

        }
    }



    try write_file(width, height, pixels);


}

pub fn main() !void {
    try build_img(960, 640);
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
