<?php declare(strict_types=1);

namespace Nlzet\Tests\Xdebug;

use PHPUnit\Framework\TestCase;

final class ExtensionTest extends TestCase
{
    public function testXdebug(): void
    {
        $this->assertEquals('256', ini_get('xdebug.max_nesting_level'));
    }
}
