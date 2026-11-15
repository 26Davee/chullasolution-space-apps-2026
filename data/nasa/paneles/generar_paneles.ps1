$ErrorActionPreference = "Stop"
$ci   = [System.Globalization.CultureInfo]::InvariantCulture
$ns   = [System.Globalization.NumberStyles]::Float
$utf8 = New-Object System.Text.UTF8Encoding($false)
$carpeta = "data\nasa\paneles"
$origen  = Join-Path $carpeta "tsis_tsi_diario.txt"

$filas = @()
$descartadas = 0
foreach ($linea in (Get-Content $origen)) {
  $l = $linea.Trim()
  if ($l -eq "" -or $l.StartsWith(";")) { continue }
  $c = $l -split '\s+'
  if ($c.Count -lt 15) { $descartadas++; continue }
  $f1 = 0.0; $fe = 0.0; $fp = 0.0
  $ok = [double]::TryParse($c[4],  $ns, $ci, [ref]$f1) -and
        [double]::TryParse($c[9],  $ns, $ci, [ref]$fe) -and
        [double]::TryParse($c[14], $ns, $ci, [ref]$fp)
  # Valores fuera de rango se consideran huecos de datos
  if (-not $ok -or $f1 -lt 1300 -or $f1 -gt 1450 -or $fe -lt 1250 -or $fe -gt 1500) { $descartadas++; continue }
  $d = $c[0].Substring(0, 8)
  $fecha = "{0}-{1}-{2}" -f $d.Substring(0,4), $d.Substring(4,2), $d.Substring(6,2)
  $filas += [pscustomobject]@{ fecha = $fecha; tsi_1au = $f1; tsi_tierra = $fe; provisional = [int]$fp }
}
if ($filas.Count -eq 0) { throw "No se leyo ningun dato. Revisa el archivo." }

# CSV reducido: solo lo que usa el juego
$salida = @("fecha,tsi_1au_wm2,tsi_tierra_wm2,provisional") +
  ($filas | ForEach-Object { "{0},{1},{2},{3}" -f $_.fecha, $_.tsi_1au.ToString("R", $ci), $_.tsi_tierra.ToString("R", $ci), $_.provisional })
[System.IO.File]::WriteAllLines((Join-Path $carpeta "tsi_diario.csv"), $salida, $utf8)

function Resumen($valores) {
  $m = $valores | Measure-Object -Minimum -Maximum -Average
  [ordered]@{
    minimo   = [math]::Round($m.Minimum, 2)
    maximo   = [math]::Round($m.Maximum, 2)
    promedio = [math]::Round($m.Average, 2)
    variacion_pico_a_pico_pct = [math]::Round(($m.Maximum - $m.Minimum) / $m.Average * 100, 2)
  }
}
$r1 = Resumen ($filas | ForEach-Object { $_.tsi_1au })
$re = Resumen ($filas | ForEach-Object { $_.tsi_tierra })

$ini = ($filas | Select-Object -First 1).fecha
$fin = ($filas | Select-Object -Last 1).fecha
$hoy = Get-Date -Format "dd/MM/yyyy"

$json = [ordered]@{
  fuente = "NASA TSIS-1 / TIM, LASP (Universidad de Colorado), nivel 3, promedios de 24 horas"
  enlace = "https://lasp.colorado.edu/tsis/data/tsi-data/"
  unidad = "W/m2"
  fecha_descarga = $hoy
  desde = $ini
  hasta = $fin
  dias_validos = $filas.Count
  dias_descartados = $descartadas
  tsi_a_1_ua = $r1
  tsi_a_distancia_de_la_tierra = $re
  dia_lunar_dias_terrestres = 29.53
  razon_eficiencia_superpaneles = $null
  nota = "Medido desde la Estacion Espacial Internacional (orbita terrestre), no en la Luna. La Luna esta a una distancia del Sol casi igual a la de la Tierra. El juego usa valores de prueba; estos datos solo respaldan que la produccion de dia sea constante."
} | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText((Join-Path $carpeta "paneles_referencia.json"), $json, $utf8)

$ficha = @"
# Ficha de procedencia: irradiancia solar para los paneles de Killawasi

- **Conjunto de datos:** TSIS-1 TIM, Total Solar Irradiance, nivel 3, promedios de 24 horas (version 5 segun el encabezado del archivo)
- **Publica:** LASP, Universidad de Colorado, para la NASA
- **Pagina oficial:** https://lasp.colorado.edu/tsis/data/tsi-data/
- **Archivo descargado:** http://lasp.colorado.edu/data/tsis/tsi_data/tsis_tsi_L3_c24h_latest.txt
- **Descargado por:** Anahi, $hoy
- **Rango de fechas:** $ini a $fin ($($filas.Count) dias validos)
- **Unidad:** W/m2
- **Licencia / condiciones de uso:** [COMPLETAR: copiar de la pagina de LASP o de la NASA]

## Columnas usadas
| Columna del archivo | Significado | En tsi_diario.csv |
|---|---|---|
| nominal_date_yyyymmdd | Fecha (YYYYMMDD) | fecha |
| tsi_1au | Irradiancia solar total a 1 UA, W/m2 | tsi_1au_wm2 |
| tsi_true_earth | Irradiancia a la distancia real de la Tierra, W/m2 | tsi_tierra_wm2 |
| provisional_flag | 1 = dato provisional, 0 = final | provisional |

## Como se usa en el juego
No cambia ningun numero de la simulacion. Respalda que un panel produzca una cantidad constante de dia y nada de noche: el Sol cambia poco de un dia a otro. El archivo se midio en orbita terrestre, no en la Luna.
"@
[System.IO.File]::WriteAllText((Join-Path $carpeta "FICHA_PANELES.md"), $ficha, $utf8)

Write-Host "Dias validos: $($filas.Count)  descartados: $descartadas  ($ini a $fin)"
Write-Host "TSI a 1 UA:    min $($r1.minimo)  max $($r1.maximo)  prom $($r1.promedio)  variacion $($r1.variacion_pico_a_pico_pct) %"
Write-Host "TSI en Tierra: min $($re.minimo)  max $($re.maximo)  prom $($re.promedio)  variacion $($re.variacion_pico_a_pico_pct) %"