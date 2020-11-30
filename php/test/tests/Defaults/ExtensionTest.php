<?php declare(strict_types=1);

namespace Nlzet\Tests\Defaults;

use PHPUnit\Framework\TestCase;
use Redis;
use NumberFormatter;
use Symfony\Component\Process\Process;

final class ExtensionTest extends TestCase
{
    public function testExif(): void
    {
        $fp = fopen(__DIR__.'/../../data/example.jpg', 'rb');
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

    public function testImageOptim(): void
    {
        $this->assertTrue(file_exists('/usr/local/bin/pngquant'));
        $this->assertTrue(file_exists('/usr/bin/optipng'));
        $this->assertTrue(file_exists('/usr/bin/pngcrush'));
        $this->assertTrue(file_exists('/usr/local/bin/pngout'));
        $this->assertTrue(file_exists('/usr/bin/gifsicle'));
        $this->assertTrue(file_exists('/usr/bin/jpegoptim'));
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

    public function testWkHtmlToPdf(): void
    {
        $this->assertTrue(file_exists('/usr/local/bin/wkhtmltopdf'));
        $this->assertTrue(file_exists('/usr/local/bin/wkhtmltoimage'));

        $processChecks = [
            [
                'cmd' => ['/usr/local/bin/wkhtmltopdf', '--version'],
                'output' => 'wkhtmltopdf 0.12.4 (with patched qt)',
            ],
            [
                'cmd' => ['/usr/local/bin/wkhtmltoimage', '--version'],
                'output' => 'wkhtmltoimage 0.12.4 (with patched qt)',
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
}
