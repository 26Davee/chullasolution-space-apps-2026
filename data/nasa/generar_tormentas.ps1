$ErrorActionPreference = "Stop"
$ci   = [System.Globalization.CultureInfo]::InvariantCulture
$ns   = [System.Globalization.NumberStyles]::Float
$utf8 = New-Object System.Text.UTF8Encoding($false)   # sin BOM, para que Godot lo lea
$carpeta = "data\nasa"

# t = segundo del juego en que llega la nube. base = nivel normal antes de la tormenta
# (null si el archivo ya empieza con la tormenta).
$eventos = @(
  @{ fecha = "2021-10-28"; base = 12.9;  t = 180 },
  @{ fecha = "2017-09-10"; base = 21.0;  t = 420 },
  @{ fecha = "2012-01-24"; base = $null; t = 660 }
)
$baseRef = ($eventos | Where-Object { $null -ne $_.base } | ForEach-Object { $_.base } |
            Measure-Object -Minimum).Minimum
$segPorHora = 0.677

$res = @()
foreach ($ev in $eventos) {
  $orig = Join-Path $carpeta ("radlab_{0}.csv" -f $ev.fecha)
  $lineas = @(Get-Content $orig)

  # El encabezado real empieza en la fila que contiene "timestamp".
  $i = 0
  while ($i -lt $lineas.Count -and $lineas[$i] -notmatch 'timestamp') { $i++ }
  if ($i -ge $lineas.Count) { throw "No encontré el encabezado en $orig" }

  $url = ""
  if ($i -gt 0) {
    $url = (($lineas[0..($i - 1)] | Where-Object { $_ -match 'https?://' }) -join " ").Trim()
  }

  $filas = $lineas[$i..($lineas.Count - 1)] | ConvertFrom-Csv
  $datos = @()
  foreach ($f in $filas) {
    $v = 0.0
    if ([double]::TryParse($f.absorbed_dose_rate, $ns, $ci, [ref]$v)) {
      $datos += [pscustomobject]@{
        ts = $f.timestamp
        v  = $v
        t  = [datetime]::Parse($f.timestamp, $ci, [System.Globalization.DateTimeStyles]::AdjustToUniversal -bor [System.Globalization.DateTimeStyles]::AssumeUniversal)
      }
    }
  }
  if ($datos.Count -eq 0) { throw "Sin datos válidos en $orig" }

  # Archivo reducido: solo timestamp y absorbed_dose_rate
  $red = Join-Path $carpeta ("radlab_{0}_reducido.csv" -f $ev.fecha)
  $salida = @("timestamp,absorbed_dose_rate") + ($datos | ForEach-Object { "{0},{1}" -f $_.ts, $_.v.ToString("R", $ci) })
  [System.IO.File]::WriteAllLines($red, $salida, $utf8)

  # Pico
  $pico = $datos | Sort-Object v -Descending | Select-Object -First 1

  # Duración: horas con dosis >= 10 veces el nivel normal
  $baseUso = if ($null -ne $ev.base) { $ev.base } else { $baseRef }
  $umbral  = 10 * $baseUso
  $sobre   = @($datos | Where-Object { $_.v -ge $umbral })
  $horas   = 0.0
  if ($sobre.Count -gt 1) {
    $horas = (($sobre | Measure-Object t -Maximum).Maximum - ($sobre | Measure-Object t -Minimum).Minimum).TotalHours
  }
  $dur = [math]::Min([math]::Max($horas * $segPorHora, 20), 30)

  $res += [pscustomobject]@{
    fecha = $ev.fecha; archivo = ("data/nasa/radlab_{0}_reducido.csv" -f $ev.fecha)
    base = $ev.base; pico = $pico.v; pico_utc = $pico.ts; t = $ev.t
    horas = $horas; dur = $dur; url = $url; filas = $datos.Count
  }
}

# Intensidad: 1.0 al pico menor y 1.5 al pico mayor, en escala logarítmica
$lmin = [math]::Log10(($res | Measure-Object pico -Minimum).Minimum)
$lmax = [math]::Log10(($res | Measure-Object pico -Maximum).Maximum)

$lista = @()
foreach ($r in $res) {
  $inten = 1 + 0.5 * ([math]::Log10($r.pico) - $lmin) / ($lmax - $lmin)
  $lista += [ordered]@{
    fecha = $r.fecha; archivo = $r.archivo; linea_base = $r.base
    pico = [math]::Round($r.pico, 2); pico_utc = $r.pico_utc
    t_juego_s = $r.t; intensidad = [math]::Round($inten, 2)
    horas_sobre_10x = [math]::Round($r.horas, 1); duracion_s = [math]::Round($r.dur, 0)
  }
}

$json = [ordered]@{
  fuente           = "NASA RadLab (OSDR), instrumento CRaTER, nave LRO (orbita la Luna)"
  campo_usado      = "absorbed_dose_rate (confirmar unidad en RadLab)"
  regla_intensidad = "1 + 0.5 * (log10(pico) - log10(pico_min)) / (log10(pico_max) - log10(pico_min))"
  regla_tiempo     = "1 hora real = 0.677 s de juego; duracion entre 20 y 30 s, medida con las horas sobre 10 veces el nivel normal"
  nota             = "Los picos son datos reales de CRaTER en orbita lunar. El momento en que llegan al juego, la intensidad y la duracion son decisiones del juego."
  eventos          = $lista
} | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText((Join-Path $carpeta "tormentas_juego.json"), $json, $utf8)

# Ficha de procedencia
$hoy = Get-Date -Format "dd/MM/yyyy"
$tabla = ($res | ForEach-Object { "| radlab_{0}_reducido.csv | {1} | {2} |" -f $_.fecha, $_.url, $_.filas }) -join "`n"
$ficha = @"
# Ficha de procedencia: tormentas solares para Killawasi

- **Conjunto de datos:** CRaTER (Cosmic Ray Telescope for the Effects of Radiation), nave LRO, orbita lunar
- **Publica:** NASA, a traves de RadLab (OSDR)
- **Enlace:** https://visualization.osdr.nasa.gov/radlab/
- **Descargado por:** Anahi, $hoy
- **Licencia / condiciones de uso:** [COMPLETAR: copiar de la pagina de NASA]
- **Unidad de absorbed_dose_rate:** [COMPLETAR: confirmar en RadLab]

## Archivos
Reducidos de la descarga original: se conservan solo timestamp y absorbed_dose_rate. Los valores no se alteraron.

| Archivo | Direccion de descarga original | Filas |
|---|---|---|
$tabla

## Columnas
| Columna | Significado |
|---|---|
| timestamp | Fecha y hora de la medicion (UTC) |
| absorbed_dose_rate | Radiacion absorbida por hora |

## Como se usa en el juego
El pico de cada tormenta define la intensidad de una nube (entre 1,0 y 1,5, en escala logaritmica). El golpe al escudo es el golpe base del modo multiplicado por esa intensidad. La duracion sale de las horas en que la dosis estuvo sobre 10 veces el nivel normal.

Los picos son datos reales de CRaTER en orbita lunar. El momento en que llegan al juego, la intensidad y la duracion son decisiones del juego. CRaTER mide en detectores de silicio: no se afirma cuanta radiacion recibiria un astronauta.
"@
[System.IO.File]::WriteAllText((Join-Path $carpeta "FICHA_PROCEDENCIA.md"), $ficha, $utf8)

$res | Format-Table fecha, pico, pico_utc, horas, dur, filas -AutoSize
Write-Host "Listo. Revisa data\nasa\tormentas_juego.json y completa licencia y unidad en la ficha."
