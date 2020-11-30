<?php declare(strict_types=1);

namespace Nlzet\Tests;

use Nlzet\DockerImages\Example;
use PHPUnit\Framework\TestCase;

final class ExampleTest extends TestCase
{
    public function testAutoload(): void
    {
        $this->assertInstanceOf(Example::class, new Example());
    }
}
