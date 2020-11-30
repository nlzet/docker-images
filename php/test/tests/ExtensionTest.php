<?php declare(strict_types=1);

namespace Nlzet\Tests;

use Knp\Snappy\Pdf;
use PHPUnit\Framework\TestCase;
use Redis;
use NumberFormatter;
use Symfony\Component\Process\Process;

final class ExtensionTest extends TestCase
{
    public function testExif(): void
    {
        $fp = fopen(__DIR__.'/../data/example.jpg', 'rb');
        if (!$fp) {
            throw new \Exception('Error: Unable to open image for reading');
        }

        $data = exif_read_data($fp);
        fclose($fp);

        $this->assertEquals('example.jpg', $data['FileName'] ?? '');
    }

    public function testIntl(): void
    {
        $fmt = numfmt_create('nl_BE', NumberFormatter::CURRENCY);
        $generated = (string) numfmt_format_currency($fmt, 1234567.891234567890000, "EUR");
        // replace nbps for comparing
        $generated = preg_replace('/[^a-zA-Z0-9\.,€]/u', ' ', $generated);

        $this->assertEquals('€ 1.234.567,89', $generated);
    }

    public function testRedis(): void
    {
        // basic testing, just class usage
        $this->assertInstanceOf(Redis::class, new Redis());
    }

    public function testImageOptimBin(): void
    {
        $this->assertTrue(file_exists('/usr/local/bin/pngquant'));
        $this->assertTrue(file_exists('/usr/local/bin/optipng'));
        $this->assertTrue(file_exists('/usr/local/bin/pngcrush'));
        $this->assertTrue(file_exists('/usr/local/bin/pngout'));
        $this->assertTrue(file_exists('/usr/local/bin/gifsicle'));
        $this->assertTrue(file_exists('/usr/local/bin/jpegoptim'));
        $this->assertTrue(file_exists('/usr/local/bin/jpegtran'));
        $this->assertTrue(file_exists('/usr/local/bin/cjpeg'));

        $processChecks = [
            [
                'cmd' => ['/usr/local/bin/pngquant', '--version'],
                'output' => '2.7.',
            ],
            [
                'cmd' => ['/usr/local/bin/optipng', '--version'],
                'output' => 'OptiPNG version 0.7.',
            ],
            [
                'cmd' => ['/usr/local/bin/pngcrush', '-version'],
                'output' => 'pngcrush 1.8.',
                'catch' => true,
            ],
            [
                'cmd' => ['/usr/local/bin/pngout'],
                'output' => 'Mar 19 2015',
                'catch' => true,
            ],
            [
                'cmd' => ['/usr/local/bin/gifsicle', '--version'],
                'output' => 'Gifsicle 1.',
            ],
            [
                'cmd' => ['/usr/local/bin/jpegoptim', '--version'],
                'output' => 'jpegoptim v1.',
            ],
            [
                'cmd' => ['/usr/local/bin/jpegtran', '-v', '--help'],
                'output' => 'mozjpeg version 4.',
                'catch' => true,
            ],
            [
                'cmd' => ['/usr/local/bin/cjpeg', '-v', '--help'],
                'output' => 'mozjpeg version 4.',
                'catch' => true,
            ],
        ];

        foreach ($processChecks as $opts) {
            $process = new Process($opts['cmd']);
            $process->enableOutput();
            $process->run();

            $output = $process->getOutput();
            $catch = ($opts['catch'] ?? false);
            if ($catch) {
                $output = $process->getErrorOutput();
            }

            $this->assertStringContainsString($opts['output'], $output);
        }
    }

    public function testGdImageResize()
    {
        $targetW = 320;
        $targetH = 240;
        $filePath = __DIR__.'/../data/example.jpg';
        $fileTargetPath = __DIR__.'/../data/example_resized.jpg';
        $resource = imagecreatefromjpeg($filePath);
        $oldw = imagesx($resource);
        $oldh = imagesy($resource);
        $temp = imagecreatetruecolor($targetW, $targetH);
        imagecopyresampled($temp, $resource, 0, 0, 0, 0, $targetW, $targetH, $oldw, $oldh);

        $this->assertEquals($targetW, imagesx($temp));
        $this->assertEquals($targetH, imagesy($temp));

        imagejpeg($temp, $fileTargetPath);
        clearstatcache();
        $resource = imagecreatefromjpeg($fileTargetPath);
        $this->assertEquals($targetW, imagesx($resource));
        $this->assertEquals($targetH, imagesy($resource));
    }

    public function testImageOptimizeExec()
    {
        $factory = new \ImageOptimizer\OptimizerFactory([
            'ignore_errors'                     => false,
            'execute_only_first_png_optimizer'  => false,
            'execute_only_first_jpeg_optimizer' => false,
        ]);

        $filePath = __DIR__.'/../data/example.jpg';
        $sizeBefore = filesize($filePath);

        $optimizer = $factory->get();
        $optimizer->optimize($filePath);

        clearstatcache();
        $this->assertTrue(filesize($filePath) < $sizeBefore);
    }

    public function testWkHtmlToPdfBin(): void
    {
        $this->assertTrue(file_exists('/usr/local/bin/wkhtmltopdf'));
        $this->assertTrue(file_exists('/usr/local/bin/wkhtmltoimage'));

        $processChecks = [
            [
                'cmd' => ['/usr/local/bin/wkhtmltopdf', '--version'],
                'output' => 'wkhtmltopdf 0.12.5 (with patched qt)',
            ],
            [
                'cmd' => ['/usr/local/bin/wkhtmltoimage', '--version'],
                'output' => 'wkhtmltoimage 0.12.5 (with patched qt)',
            ],
        ];

        foreach ($processChecks as $opts) {
            $process = new Process($opts['cmd']);
            $process->enableOutput();
            $process->run();

            $output = $process->getOutput();
            $this->assertStringContainsString($opts['output'], $output);
        }
    }

    public function testWkHtmlToPdfExec(): void
    {
        $target = __DIR__.'/../data/test.pdf';
        $snappy = new Pdf('/usr/local/bin/wkhtmltopdf');
        file_put_contents($target, $snappy->getOutput('http://www.github.com'));

        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime = finfo_file($finfo, $target);
        finfo_close($finfo);

        $this->assertEquals('application/pdf', $mime);
    }
}
