# Scripts

### burgerbot.rb

Helps to find a Bürgeramt appointment in Berlin

`ruby burgerbot.rb`

### bus_stop_info.rb

Information about a BVG transit stop

```
ruby bus_stop_info.rb hermannplatz

U Hermannplatz
[2min] M41 S+U Hauptbahnhof [average]
[2min] U8 S+U Hermannstr. on platform 1 [empty]
[4min] 194 S Friedrichsfelde Ost [empty]
[4min] U7 S+U Rathaus Spandau on platform 2 [empty]
[5min] 171 Flughafen BER Terminal 5 [empty]
[6min] M41 Sonnenallee/Baumschulenstr. [empty]
[6min] 171 Flughafen BER Terminal 5 [empty]
[6min] M29 Grunewald, Roseneck [empty]
[7min] M41 Sonnenallee/Baumschulenstr. [empty]
[7min] 194 S Friedrichsfelde Ost [empty]
[7min] M29 Grunewald, Roseneck [empty]
[8min] U7 U Rudow on platform 1 [empty]
[9min] U8 S+U Wittenau on platform 2 [empty]

ruby bus_stop_info.rb hermannplatz U8

U Hermannplatz
[1min] U8 S+U Hermannstr. on platform 1 [empty]
[8min] U8 S+U Wittenau on platform 2 [empty]
[9min] U8 S+U Hermannstr. on platform 1 [empty]
```

### cheapest_dcl_land.rb

Find the current cheapest land for sale in Decentraland's marketplace

```
ruby cheapest_dcl_land.rb

Fetching data...
3360 MANA: 106,-101
3480 MANA: 108,-120
3480 MANA: 109,-120
3500 MANA: -145,-121
3500 MANA: 78,-105
3550 MANA: 149,17
3650 MANA: 75,-144
3750 MANA: 141,-53
3825 MANA: 143,-17
3888 MANA: 126,-19
```

### formatted_ddate.rb

Returns the current discordian season and date along with planetary rulers of the moment.
Requires the `planetary_rulers.rb` script

```
ruby formatted_ddate.rb

4/42 Sol/Jupiter
```

### housekeeping_analyzer.rb

Counts TODO and FIXME lines for a given github repository path

```
ruby housekeeping_analyzer.rb ~/programming/dcl-metrics/backend/

Blaming lines: 100% (33/33), done.
Blaming lines: 100% (60/60), done.
Blaming lines: 100% (194/194), done.
notes/parsing-scene-data: 4
lib/jobs/process_daily_user_activity.rb: 3
lib/services/fetch_dcl_user_data.rb: 2
lib/jobs/process_daily_user_stats.rb: 2
spec/user_activity_spec.rb: 1
spec/daily_stats_spec.rb: 1
lib/models/parcel_traffic.rb: 1
lib/jobs/process_snapshot.rb: 1
README.md: 1
.github/workflows/deploy_staging.yaml: 1
.github/workflows/deploy_prod.yaml: 1
```

### i_ching.rb

> The I Ching is not magic; it is science we don't understand
> - Terence McKenna

Cast the I Ching

```
ruby i_ching.rb

HEXAGRAM 50: FIRE over WIND
https://www.jamesdekorne.com/GBCh/hex50.htm
```

Programatically, this script returns data in the following format:

```
{
  lower_lines: ["_ _", "___", "___"],
  lower_trigram: ["☴", "wind"],
  upper_lines: ["___", "_ _", "___"],
  upper_trigram: ["☲", "fire"],
  hexgram: 50
}
```

For interpretation, see [The Gnostic Book of Changes](https://www.jamesdekorne.com/GBCh/GBCh.htm)

### planetary_rulers.rb

Returns the planetary rulers of the moment. Requires an ipgeolocation.io API key

```
ruby planetary_rulers.rb

sol/jupiter
```

Programatically, this script returns data in the following format:

```
{
  daily_ruler: 'sol',
  hourly_ruler: 'jupiter'
}
```
