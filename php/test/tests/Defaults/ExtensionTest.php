<?php declare(strict_types=1);

namespace Nlzet\Tests\Defaults;

use PHPUnit\Framework\TestCase;
use Redis;
use NumberFormatter;

final class ExtensionTest extends TestCase
{
    public function testApcu(): void
    {
        $this->assertFalse(apcu_fetch('test'));

        apcu_store('test', true);
        $this->assertTrue(apcu_fetch('test'));
    }

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
}
