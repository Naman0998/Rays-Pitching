#Question 1 AVG Pitches Per at Bat Analysis

#1a AVG Pitches Per At Bat (LastPitchRays)
select avg(1 * pitch_number) avg_pitch_num
from lastpitchrays;

#1b AVG Pitches Per At Bat Home Vs Away (LastPitchRays) -> Union
SELECT 
	'Home' TypeofGame,
	AVG(1.00 * Pitch_number) AvgNumofPitchesPerAtBat
FROM lastpitchrays
Where home_team = 'TB'
UNION
SELECT 
	'Away' TypeofGame,
	AVG(pitch_number) AvgNumofPitchesPerAtBat
FROM lastpitchrays
Where away_team = 'TB';

#1c AVG Pitches Per At Bat Lefty Vs Righty  -> Case Statement 
select
(case when Batter_position = 'L' then avg(pitch_number) end) lefthandbats,
(case when Batter_position = 'R' then avg(pitch_number) end) righthandbats
from lastpitchrays;

#1d AVG Pitches Per At Bat Lefty Vs Righty Pitcher | Each Away Team -> Partition By
SELECT DISTINCT
	home_team,
	Pitcher_position,
	AVG(pitch_number) OVER (Partition by home_team, Pitcher_position) avgpitches_LvsR
FROM lastpitchrays
Where away_team = 'TB';

#1e Top 3 Most Common Pitch for at bat 1 through 10, and total amounts (LastPitchRays)
with totalpitchsequence as
	(select distinct pitch_name,
	pitch_number,
	count(pitch_name) over (partition by pitch_name, pitch_number) Pitch_Frequency
	from lastpitchrays
    where pitch_number <11),
Pitch_Frequency_Rank as (
	select
    pitch_name,
    pitch_number,
    Pitch_Frequency,
    rank() over (partition by pitch_number order by Pitch_Frequency desc) Pitch_F_Rank
    from totalpitchsequence)
select*
from Pitch_Frequency_Rank
where Pitch_F_Rank <4;

#1f AVG Pitches Per at Bat Per Pitcher with 20+ Innings | Order in descending (LastPitchRays + RaysPitchingStats)
SELECT RP.Name,
avg(LP.pitch_number) avgpitches
FROM lastpitchrays LP
join rayspitching RP on RP.pitcher_id = LP.pitcher
where IP >=20
order by avg(LP.pitch_number) desc;


#Question 2 Last Pitch Analysis

#2a Count of the Last Pitches Thrown in Desc Order (LastPitchRays)
select pitch_name,
count(*) timesthrown 
from lastpitchrays
group by pitch_name
order by count(*) desc;

#2b Count of the different last pitches Fastball or Offspeed (LastPitchRays)
SELECT
	sum(case when pitch_name in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) Fastball,
	sum(case when pitch_name NOT in ('4-Seam Fastball', 'Cutter') then 1 else 0 end) Offspeed
FROM lastpitchrays;

#2c Percentage of the different last pitches Fastball or Offspeed (LastPitchRays)
SELECT
	100 * sum(case when pitch_name in ('4-Seam Fastball', 'Cutter') then 1 else 0 end)/ count(*) Fastball,
	100 * sum(case when pitch_name NOT in ('4-Seam Fastball', 'Cutter') then 1 else 0 end)/ count(*) Offspeed
FROM lastpitchrays;

#2d Top 5 Most common last pitch for a Relief Pitcher vs Starting Pitcher (LastPitchRays + RaysPitchingStats)
select *
from (select
			a.Pos,
            a.pitch_name,
            a.timesthrown,
            rank() over (partition by a.Pos order by timesthrown desc) PitchRank
	from(
		select RP.Pos, 
				LP.pitch_name, 
				count(*) timesthrown
        from lastpitchrays LP
        join rayspitching RP on RP.pitcher_id = LP.pitcher
        group by RP.Pos, LP.pitch_name
        ) a
	)b
where b.PitchRank <6;
	

#Question 3 Homerun analysis

#3a What pitches have given up the most HRs (LastPitchRays) 
select pitch_name, count(*) HRs
from lastpitchrays
where events = 'home_run'
group by pitch_name
order by count(*) desc;

#3b Show HRs given up by zone and pitch

select zone, pitch_name, count(*) HRs
from lastpitchrays
where events = 'home_run'
group by zone, pitch_name
order by count(*) desc;

#3c Show HRs for each count type -> Balls/Strikes + Type of Pitcher

select RP.Pos, LP.balls, LP.strikes, count(*) HRs
from lastpitchrays LP
join rayspitching RP ON RP.pitcher_id = LP.pitcher
where events = 'home_run'
group by RP.Pos, LP.balls, LP.strikes
order by count(*) desc;

#3d Show Each Pitchers Most Common count to give up a HR (Min 30 IP)


#Question 4 Shane McClanahan

#4a AVG Release speed, spin rate,  strikeouts, most popular zone ONLY USING LastPitchRays

select 
	round(avg(release_speed),2) AvgReleaseSpeed,
	round(avg(release_spin_rate),2) AvgSpinRate,
	Sum(case when events = 'strikeout' then 1 else 0 end) strikeouts,
	MAX(zones.zone) as Zone
from lastpitchrays LP
join (
	select pitcher, zone, count(*) zonenum
	from lastpitchrays LP
	where player_name = 'McClanahan, Shane'
	group by pitcher, zone
	order by count(*) desc

) zones on zones.pitcher = LP.pitcher
where player_name = 'McClanahan, Shane';

#4b top pitches for each infield position where total pitches are over 5, rank them

select *
from (
	select pitch_name, count(*) timeshit, 'Third' Position
	from lastpitchrays
	where hit_location = 5 and player_name = 'McClanahan, Shane'
	group by pitch_name
	union
	select pitch_name, count(*) timeshit, 'Short' Position
	from lastpitchrays
	where hit_location = 6 and player_name = 'McClanahan, Shane'
	group by pitch_name
	union
	select pitch_name, count(*) timeshit, 'Second' Position
	from lastpitchrays
	where hit_location = 4 and player_name = 'McClanahan, Shane'
	group by pitch_name
	union
	select pitch_name, count(*) timeshit, 'First' Position
	from lastpitchrays
	where hit_location = 3 and player_name = 'McClanahan, Shane'
	group by pitch_name
) a
where timeshit > 4
order by timeshit desc;

#4c Show different balls/strikes as well as frequency when someone is on base 

select balls, strikes, count(*) frequency
from lastpitchrays
where (on_3b is NOT NULL or on_2b is NOT NULL or on_1b is NOT NULL)
and player_name = 'McClanahan, Shane'
group by balls, strikes
order by count(*) desc;

#4d What pitch causes the lowest launch speed'

select pitch_name, round(avg(launch_speed),2) LaunchSpeed
from lastpitchrays
where player_name = 'McClanahan, Shane'
group by pitch_name
order by avg(launch_speed);