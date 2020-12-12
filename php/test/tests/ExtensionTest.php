<?php declare(strict_types=1);

namespace Nlzet\Tests;

use ImageOptimizer\Exception\Exception as OptimizeException;
use ImageOptimizer\OptimizerFactory;
use Knp\Snappy\Pdf;
use PHPUnit\Framework\TestCase;
use Redis;
use NumberFormatter;
use Symfony\Component\Process\Process;

final class ExtensionTest extends TestCase
{
    private $name;

    protected function setUp(): void
    {
        $this->name = sprintf(
            'php%s',
            preg_replace('/[^a-zA-Z0-9]+/', '', PHP_VERSION)
        );
    }

    protected function fileCopy(string $filePath, array $options)
    {
        if (isset($options['rename'])) {
            $targetPath = sprintf('%s/%s', pathinfo($filePath, PATHINFO_DIRNAME), $options['rename']);
        } elseif (isset($options['extension'])) {
            $targetPath = sprintf('%s.%s', $filePath, $options['extension']);
        } else {
            throw new \Exception('Choose backup strategy rename or extension');
        }

        clearstatcache();
        if (!file_exists($filePath)) {
            throw new \Exception(sprintf('Cannot backup file, file does not exist "%s"', $filePath));
        }

        copy($filePath, $targetPath);
    }

    protected function fileRestore(string $filePath, $extension = 'tmpbak', $remove = true)
    {
        clearstatcache();
        $backupFilePath = sprintf('%s.%s', $filePath, $extension);
        if (!file_exists($backupFilePath)) {
            throw new \Exception(sprintf('Backup file does not exist "%s"', $backupFilePath));
        }

        @unlink($filePath);
        @copy($backupFilePath, $filePath);
        if ($remove) {
            unlink($backupFilePath);
        }
    }

    const OPTIMIZE_DEFAULTS = [
        'ignore_errors'                     => false,
        'execute_only_first_png_optimizer'  => false,
        'execute_only_first_jpeg_optimizer' => false,
        'optipng_options'                   => ['-clobber', '--force'],
        'pngquant_options'                  => ['--force'/*, '--strip'*/], // todo: add --strip when installed pngquant version supports it.
        'pngcrush_options'                  => ['-reduce', '-q', '-ow'],
        'pngout_options'                    => ['-s3', '-q', '-y', '-c2', '-d8'],
        'gifsicle_options'                  => ['-b', '-O5'],
        'jpegoptim_options'                 => ['--strip-all', '-m 85'],
        'jpegtran_options'                  => ['-optimize', '-progressive'],
        'advpng_options'                    => ['-z', '-4', '-q'],
        'svgo_options'                      => ['--disable=cleanupIDs'],
        'optipng_bin' => '',
        'pngquant_bin' => '',
        'pngcrush_bin' => '',
        'advpng_bin' => '',
        'gifsicle_bin' => '',
        'jpegoptim_bin' => '',
        'jpegtran_bin' => '',
        'pngout_bin' => '',
        'custom_optimizers'                 => [],
    ];

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
        $this->assertTrue(file_exists('/usr/local/bin/gifsicle'));
        $this->assertTrue(file_exists('/usr/local/bin/jpegoptim'));
        $this->assertTrue(file_exists('/usr/local/bin/jpegtran'));

        $processChecks = [
            [
                'cmd' => ['/usr/local/bin/pngquant', '--version'],
                'output' => '2.',
            ],
            [
                'cmd' => ['/usr/local/bin/optipng', '--version'],
                'output' => 'OptiPNG version 0.7.',
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
                'output' => 'mozjpeg version 3.',
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

        @unlink($fileTargetPath);
    }

    public function provideImageOptimizeTests()
    {
        return [
            [__DIR__.'/../data/sample.jpg', 'jpegoptim', ['optimizers' => ['jpegoptim']]],
            [__DIR__.'/../data/sample.jpg', 'jpegtran', ['optimizers' => ['jpegtran']]],
            [__DIR__.'/../data/sample.jpeg', 'jpegoptim', ['optimizers' => ['jpegoptim']]],
            [__DIR__.'/../data/sample.jpeg', 'jpegtran', ['optimizers' => ['jpegtran']]],
            [__DIR__.'/../data/sample.png', 'optipng', ['optimizers' => ['optipng']]],
            [__DIR__.'/../data/sample.png', 'pngquant', ['optimizers' => ['pngquant']]],
        ];
    }

    /**
     * @dataProvider provideImageOptimizeTests
     */
    public function testImageOptimizeExec(string $filePath, string $optimizerName, array $options)
    {
        if (!file_exists($filePath)) {
            throw new \Exception(sprintf('Cannot find source image "%s"', $filePath));
        }

        $command = '';
        $optimizers = [];
        foreach (self::OPTIMIZE_DEFAULTS as $defaultKey => $defaultValue) {
            if (!isset($options[$defaultKey])) {
                $options[$defaultKey] = $defaultValue;
            }
        }

        if (isset($options['optimizers'])) {
            foreach ($options['optimizers'] as $optimizer) {
                switch ($optimizer) {
                    case 'optipng':
                        $options['optipng_bin'] = $optimizers[] = '/usr/local/bin/optipng';
                        $command = sprintf('%s %s', end($optimizers), implode(' ', $options['optipng_options'] ?? []));
                        break;
                    case 'pngquant':
                        $options['pngquant_bin'] = $optimizers[] = '/usr/local/bin/pngquant';
                        $command = sprintf('%s %s', end($optimizers), implode(' ', $options['pngquant_options'] ?? []));
                        break;
                    case 'pngcrush':
                        $options['pngcrush_bin'] = $optimizers[] = '/usr/local/bin/pngcrush';
                        $command = sprintf('%s %s', end($optimizers), implode(' ', $options['pngcrush_options'] ?? []));
                        break;
                    case 'gifsicle':
                        $options['gifsicle_bin'] = $optimizers[] = '/usr/local/bin/gifsicle';
                        $command = sprintf('%s %s', end($optimizers), implode(' ', $options['gifsicle_options'] ?? []));
                        break;
                    case 'jpegoptim':
                        $options['jpegoptim_bin'] = $optimizers[] = '/usr/local/bin/jpegoptim';
                        $command = sprintf('%s %s', end($optimizers), implode(' ', $options['jpegoptim_options'] ?? []));
                        break;
                    case 'jpegtran':
                        $options['jpegtran_bin'] = $optimizers[] = '/usr/local/bin/jpegtran';
                        $command = sprintf('%s %s', end($optimizers), implode(' ', $options['jpegtran_options'] ?? []));
                        break;
                    default:
                        throw new \Exception(sprintf('Unknown optimizer "%s"', $optimizer));
                }

                $command .= ' '.$filePath;
            }

            unset($options['optimizers']);
        }

        $factory = new OptimizerFactory($options);

        $this->fileCopy($filePath, ['extension' => 'tmpbak']);
        clearstatcache();
        $sizeBefore = filesize($filePath);

        $optimizer = $factory->get($optimizerName);
        $errorMessage = sprintf(
            'Unsuccesfull optimize: %s (optimizers: %s). Command: %s',
            $filePath,
            implode(', ', $optimizers),
            $command
        );

        try {
            $optimizer->optimize($filePath);
        } catch (OptimizeException $optimizeException) {
            $this->fileRestore($filePath);

            throw new \Exception($errorMessage. ': Exception: '.$optimizeException->getMessage());
        }

        clearstatcache();
        $fileSize = filesize($filePath);

        $this->fileCopy($filePath, [
            'rename' => sprintf(
                'out_%s_%s_%s',
                $this->name,
                $optimizerName,
                pathinfo($filePath, PATHINFO_BASENAME)
            )
        ]);

        $errorMessage .= sprintf(
            ': size before: %s, now: %s.',
            $sizeBefore,
            $fileSize
        );
        $this->assertTrue($fileSize < $sizeBefore, $errorMessage);

        $this->fileRestore($filePath);
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
        $target = __DIR__.sprintf('/../data/out_%s_wkhtmltopdf_fromhtml.pdf', $this->name);
        $snappy = new Pdf('/usr/local/bin/wkhtmltopdf');
        $input = file_get_contents(__DIR__.'/../data/template.html');
        file_put_contents($target, $snappy->getOutputFromHtml($input, [
            'encoding'                => 'utf-8',
            'dpi'                     => 300,
            'enable-external-links'   => true,
            'enable-internal-links'   => true,
            'page-size'               => 'A4',
            'disable-smart-shrinking' => true,
            'margin-bottom'           => 0,
            'margin-right'            => 0,
            'margin-top'              => 0,
            'margin-left'             => 0,
        ]));

        $data = file_get_contents($target);
        $this->assertTrue(1 === preg_match("/^%PDF-1./", $data));

        @unlink($target);
    }
}
