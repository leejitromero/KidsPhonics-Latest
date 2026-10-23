param([string]$Source = 'output/banner_tittle_source.png')

# Deterministic cutouts of the supplied pixels. No image generation, resizing,
# recoloring or text rendering is used. The original source is never written.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$project = Split-Path $PSScriptRoot -Parent
$sourcePath = (Resolve-Path -LiteralPath (Join-Path $project $Source)).Path
$destination = Join-Path $project 'assets/images/home_banner'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;

public static class HomeBannerExtraction {
    static GraphicsPath Outline(string data) {
        var path = new GraphicsPath();
        var tokens = data.Split(new char[]{' ', '\r', '\n', '\t'},
            StringSplitOptions.RemoveEmptyEntries);
        int i = 0; float x = 0, y = 0;
        Func<float> n = () => float.Parse(tokens[i++], CultureInfo.InvariantCulture);
        while (i < tokens.Length) {
            string op = tokens[i++];
            if (op == "M") { x = n(); y = n(); path.StartFigure(); }
            else if (op == "L") {
                float nx = n(), ny = n(); path.AddLine(x, y, nx, ny); x = nx; y = ny;
            } else if (op == "C") {
                float a = n(), b = n(), c = n(), d = n(), nx = n(), ny = n();
                path.AddBezier(x, y, a, b, c, d, nx, ny); x = nx; y = ny;
            } else if (op == "Z") path.CloseFigure();
            else throw new ArgumentException(op);
        }
        return path;
    }
    public static void Cut(string source, string destination, int x, int y,
        int width, int height, string outline) {
        using (var original = new Bitmap(source))
        using (var output = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (var mask = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (var path = Outline(outline)) {
            using (var transform = new Matrix()) {
                transform.Translate(-x, -y); path.Transform(transform);
            }
            using (var g = Graphics.FromImage(mask)) {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.FillPath(Brushes.White, path);
            }
            for (int row = 0; row < height; row++) {
                for (int col = 0; col < width; col++) {
                    int alpha = mask.GetPixel(col, row).A;
                    if (alpha == 0) continue;
                    var pixel = original.GetPixel(x + col, y + row);
                    output.SetPixel(col, row, Color.FromArgb(
                        alpha * pixel.A / 255, pixel.R, pixel.G, pixel.B));
                }
            }
            output.Save(destination, ImageFormat.Png);
        }
    }
}
'@

$parts = @(
    @{
        Name = 'logo'; X = 112; Y = 0; Width = 1350; Height = 585
        Outline = @'
M 351 0 L 405 0 C 414 18 407 34 400 42 C 428 55 429 79 412 90
C 425 111 410 134 393 144 L 390 157
C 435 125 482 116 529 110 C 621 90 711 84 783 85
C 904 84 1005 100 1087 122 L 1178 143
L 1179 126 C 1160 109 1161 87 1174 76 C 1154 58 1165 33 1184 25
L 1193 0 L 1245 0 C 1243 19 1238 35 1233 43 C 1263 54 1269 78 1250 92
C 1262 116 1248 139 1224 146 L 1225 160 L 1270 165 L 1295 132
C 1306 121 1317 126 1324 139 L 1345 178 L 1372 187 C 1390 192 1391 211 1375 221
C 1400 246 1415 267 1426 296 C 1443 317 1453 342 1456 375
C 1464 417 1452 465 1429 499 C 1410 531 1385 551 1348 559
L 1291 558 L 1275 576 L 1256 563 L 1234 566 L 1228 546
C 1129 522 1000 489 897 478 C 713 454 569 480 386 526
L 352 537 L 354 550 L 340 555 L 329 549 L 309 553 L 304 542
L 255 542 L 244 549 L 231 544 L 221 555 L 209 548 L 213 534
C 198 532 184 525 176 515 L 159 530 C 143 541 129 532 130 517
L 132 497 L 117 482 C 110 470 116 458 134 451 L 148 443 L 148 421
C 126 399 122 376 127 349 C 130 298 151 257 182 225 L 207 207
L 201 192 C 197 181 203 173 216 169 L 239 160 L 251 136
C 259 120 274 125 282 139 L 300 163 L 332 154 L 346 146
L 345 129 C 325 118 327 99 340 88 C 321 73 327 49 347 40
C 340 28 345 10 351 0 Z
M 1413 521 L 1424 537 L 1438 540 L 1436 551 L 1425 558 L 1425 571
L 1413 568 L 1403 576 L 1397 563 L 1386 557 L 1391 547 L 1405 541 Z
'@
    },
    @{
        Name = 'panel'; X = 143; Y = 529; Width = 1235; Height = 333
        Outline = @'
M 153 634 C 161 588 189 565 239 563 L 324 563 L 335 541 L 358 536 L 359 563
L 1009 561 L 1025 568 L 1042 583 L 1094 579 L 1102 549 L 1126 550
L 1128 576 L 1290 573 C 1338 575 1363 596 1369 630
C 1381 689 1371 746 1364 784 C 1358 831 1330 852 1276 857
L 1074 851 L 1010 849 L 974 854 L 236 851 C 185 850 157 835 150 805
C 140 750 144 689 153 634 Z
'@
    },
    @{
        Name = 'trophy'; X = 290; Y = 872; Width = 156; Height = 128
        Outline = @'
M 323 886 C 343 874 384 874 409 886 L 412 900
C 454 880 452 930 422 946 L 399 949 C 393 958 384 965 375 968
L 376 978 L 395 982 L 395 993 C 375 1000 343 996 333 991 L 335 980 L 354 978
L 354 964 L 336 952 C 302 951 287 925 296 903 C 300 891 311 889 324 893 Z
M 322 905 C 302 893 305 925 326 932 Z
M 412 910 C 432 899 435 924 408 935 Z
'@
    },
    @{
        Name = 'xp'; X = 470; Y = 867; Width = 106; Height = 145
        Outline = @'
M 508 871 L 549 871 C 558 871 560 877 554 887 L 537 916 L 562 916
C 572 917 573 924 568 933 L 512 1000 C 504 1008 493 1005 495 991
L 502 952 L 481 951 C 471 950 470 944 475 934 Z
'@
    },
    @{
        Name = 'star'; X = 604; Y = 867; Width = 143; Height = 136
        Outline = @'
M 663 876 C 670 865 680 867 686 878 L 701 908 L 731 914 C 744 916 746 927 737 936
L 716 955 L 719 983 C 721 998 712 1004 699 997 L 675 983 L 649 997
C 635 1004 627 995 630 980 L 634 954 L 611 935 C 602 926 607 916 620 913
L 649 908 Z
'@
    },
    @{
        Name = 'fire'; X = 780; Y = 856; Width = 131; Height = 146
        Outline = @'
M 791 922 C 799 904 806 897 815 891 L 816 910 C 835 897 830 877 834 860
C 849 857 871 879 878 899 L 881 883 C 903 909 914 941 904 966
C 894 992 874 998 848 997 C 813 1001 790 986 785 964 C 781 948 784 935 791 922 Z
'@
    },
    @{
        Name = 'flower'; X = 936; Y = 889; Width = 114; Height = 108
        Outline = @'
M 977 915 C 974 889 998 887 1008 904 L 1011 917
C 1033 904 1052 922 1045 937 L 1030 947 C 1046 964 1037 986 1018 980
L 1006 970 C 1002 998 980 996 977 975 L 974 966 C 954 984 935 969 946 951
L 952 945 C 932 938 935 917 951 916 L 977 922 Z
'@
    }
)

$report = foreach ($part in $parts) {
    $target = Join-Path $destination ($part.Name + '.png')
    [HomeBannerExtraction]::Cut($sourcePath, $target, $part.X, $part.Y,
        $part.Width, $part.Height, $part.Outline)
    [pscustomobject]@{
        asset = "assets/images/home_banner/$($part.Name).png"
        sourceRect = @($part.X, $part.Y, $part.Width, $part.Height)
        sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    }
}
@{
    source = $Source
    sourceSha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
    method = 'Original RGB pixels with antialiased silhouette alpha masks'
    assets = @($report)
} | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 (Join-Path $project 'tools/home_banner_extraction.json')
$report | Format-Table -AutoSize
