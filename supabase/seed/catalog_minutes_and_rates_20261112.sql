-- 2026-11-12 (APPLIED). Minutes of labor per unit for project items (crew-minutes), visit-task prices (≈$1/min at the $385 day), and rate corrections where labor at Cotto's productivity exceeded the rate.
-- Model: minutes/unit × crew-hour SELL rate (Cotto $30–65/hr ÷ 0.7 margin → $45 general · $55 masonry/tile/carpentry · $65 electrical/AC · $90 plumbing · $60 handyman day).
update public.catalog_items set rate=20 where id='h01';
update public.catalog_items set rate=45 where id='h02';
update public.catalog_items set rate=60 where id='h03';
update public.catalog_items set rate=30 where id='h04';
update public.catalog_items set rate=45 where id='h05';
update public.catalog_items set rate=20 where id='h06';
update public.catalog_items set rate=30 where id='h07';
update public.catalog_items set rate=30 where id='h08';
update public.catalog_items set rate=60 where id='h09';
update public.catalog_items set rate=45 where id='h10';
update public.catalog_items set rate=30 where id='h11';
update public.catalog_items set rate=90 where id='h12';
update public.catalog_items set rate=90 where id='h13';
update public.catalog_items set rate=45 where id='h14';
update public.catalog_items set rate=45 where id='h15';
update public.catalog_items set rate=30 where id='h16';
update public.catalog_items set rate=30 where id='h17';
update public.catalog_items set rate=30 where id='h18';
update public.catalog_items set rate=30 where id='h19';
update public.catalog_items set rate=30 where id='h20';
update public.catalog_items set rate=60 where id='h21';
update public.catalog_items set rate=45 where id='h22';
update public.catalog_items set rate=60 where id='h23';
update public.catalog_items set rate=60 where id='h24';
update public.catalog_items set rate=20 where id='h25';
update public.catalog_items set rate=30 where id='h26';
update public.catalog_items set rate=60 where id='h27';
update public.catalog_items set minutes=2.0 where id='t01-i01';
update public.catalog_items set minutes=2.5 where id='t01-i02';
update public.catalog_items set minutes=2.0 where id='t01-i03';
update public.catalog_items set minutes=1.0 where id='t01-i04';
update public.catalog_items set minutes=1.0 where id='t01-i05';
update public.catalog_items set minutes=2.0 where id='t01-i06';
update public.catalog_items set minutes=120 where id='t01-i07';
update public.catalog_items set minutes=6 where id='t01-i08';
update public.catalog_items set minutes=8 where id='t01-i09';
update public.catalog_items set minutes=2.5 where id='t01-i10';
update public.catalog_items set minutes=6 where id='t01-i11';
update public.catalog_items set minutes=3.0 where id='t02-i01';
update public.catalog_items set minutes=4.0 where id='t02-i02';
update public.catalog_items set minutes=4.0 where id='t02-i03';
update public.catalog_items set minutes=3.0 where id='t02-i04';
update public.catalog_items set minutes=1.5 where id='t02-i05';
update public.catalog_items set minutes=15 where id='t02-i06';
update public.catalog_items set minutes=1.5 where id='t02-i07';
update public.catalog_items set minutes=6 where id='t03-i01';
update public.catalog_items set minutes=240 where id='t03-i02';
update public.catalog_items set minutes=6 where id='t03-i03';
update public.catalog_items set minutes=5 where id='t03-i04';
update public.catalog_items set minutes=5 where id='t03-i05';
update public.catalog_items set minutes=720 where id='t03-i06';
update public.catalog_items set minutes=20 where id='t03-i07';
update public.catalog_items set minutes=90 where id='t04-i01';
update public.catalog_items set minutes=120 where id='t04-i02';
update public.catalog_items set minutes=60 where id='t04-i03';
update public.catalog_items set minutes=90 where id='t04-i04';
update public.catalog_items set minutes=30 where id='t04-i05';
update public.catalog_items set minutes=150 where id='t04-i06';
update public.catalog_items set minutes=120 where id='t04-i07';
update public.catalog_items set minutes=120 where id='t04-i08';
update public.catalog_items set minutes=10 where id='t04-i09';
update public.catalog_items set minutes=120 where id='t04-i10';
update public.catalog_items set minutes=60 where id='t04-i11';
update public.catalog_items set minutes=120 where id='t04-i12';
update public.catalog_items set minutes=180 where id='t04-i13';
update public.catalog_items set minutes=90 where id='t04-i14';
update public.catalog_items set minutes=60 where id='t05-i01';
update public.catalog_items set minutes=60 where id='t05-i02';
update public.catalog_items set minutes=75 where id='t05-i03';
update public.catalog_items set minutes=45 where id='t05-i04';
update public.catalog_items set minutes=75 where id='t05-i05';
update public.catalog_items set minutes=150 where id='t05-i06';
update public.catalog_items set minutes=240 where id='t05-i07';
update public.catalog_items set minutes=45 where id='t05-i08';
update public.catalog_items set minutes=12 where id='t05-i10';
update public.catalog_items set minutes=30 where id='t05-i11';
update public.catalog_items set minutes=90 where id='t05-i13';
update public.catalog_items set minutes=1.5 where id='t07-i01';
update public.catalog_items set minutes=0.4 where id='t07-i02';
update public.catalog_items set minutes=0.4 where id='t07-i03';
update public.catalog_items set minutes=0.3 where id='t07-i04';
update public.catalog_items set minutes=0.4 where id='t07-i05';
update public.catalog_items set minutes=0.4 where id='t07-i06';
update public.catalog_items set minutes=4 where id='t07-i07';
update public.catalog_items set minutes=10 where id='t07-i08';
update public.catalog_items set minutes=240 where id='t07-i09';
update public.catalog_items set minutes=600 where id='t06-i01';
update public.catalog_items set minutes=720 where id='t06-i02';
update public.catalog_items set minutes=960 where id='t06-i03';
update public.catalog_items set minutes=180 where id='t06-i04';
update public.catalog_items set minutes=45 where id='t06-i05';
update public.catalog_items set minutes=60 where id='t06-i06';
update public.catalog_items set minutes=60 where id='t06-i07';
update public.catalog_items set minutes=0.4 where id='t08-i01';
update public.catalog_items set minutes=0.5 where id='t08-i02';
update public.catalog_items set minutes=0.4 where id='t08-i03';
update public.catalog_items set minutes=0.5 where id='t08-i04';
update public.catalog_items set minutes=3 where id='t08-i05';
update public.catalog_items set minutes=6 where id='t09-i01';
update public.catalog_items set minutes=8 where id='t09-i02';
update public.catalog_items set minutes=6 where id='t09-i03';
update public.catalog_items set minutes=3 where id='t09-i04';
update public.catalog_items set minutes=4 where id='t09-i05';
update public.catalog_items set minutes=3 where id='t09-i06';
update public.catalog_items set minutes=3 where id='t09-i07';
update public.catalog_items set minutes=2 where id='t09-i08';
update public.catalog_items set minutes=960 where id='t10-i01';
update public.catalog_items set minutes=60 where id='t10-i02';
update public.catalog_items set minutes=15 where id='t10-i03';
update public.catalog_items set minutes=6 where id='t10-i04';
update public.catalog_items set minutes=30 where id='t10-i05';
update public.catalog_items set minutes=4 where id='t10-i06';
update public.catalog_items set minutes=180 where id='t11-i01';
update public.catalog_items set minutes=240 where id='t11-i02';
update public.catalog_items set minutes=120 where id='t11-i03';
update public.catalog_items set minutes=45 where id='t11-i04';
update public.catalog_items set minutes=30 where id='t11-i05';
update public.catalog_items set minutes=90 where id='t11-i06';
update public.catalog_items set minutes=30 where id='t11-i07';
update public.catalog_items set minutes=60 where id='t11-i08';
update public.catalog_items set minutes=240 where id='t12-i01';
update public.catalog_items set minutes=4 where id='t12-i02';
update public.catalog_items set minutes=4 where id='t12-i03';
update public.catalog_items set minutes=0.5 where id='t12-i04';
update public.catalog_items set minutes=2.5 where id='t12-i05';
update public.catalog_items set minutes=90 where id='t12-i06';
update public.catalog_items set minutes=10 where id='t12-i07';
update public.catalog_items set minutes=4 where id='t13-i01';
update public.catalog_items set minutes=8 where id='t13-i02';
update public.catalog_items set minutes=3 where id='t13-i03';
update public.catalog_items set minutes=150 where id='t13-i04';
update public.catalog_items set minutes=300 where id='t13-i05';
update public.catalog_items set minutes=60 where id='t13-i06';
update public.catalog_items set minutes=60 where id='t13-i07';
update public.catalog_items set minutes=240 where id='t14-i01';
update public.catalog_items set minutes=180 where id='t14-i02';
update public.catalog_items set minutes=120 where id='t14-i03';
update public.catalog_items set minutes=5 where id='t14-i04';
update public.catalog_items set minutes=180 where id='t14-i05';
update public.catalog_items set minutes=2 where id='t14-i06';
with c(item_id,new_rate) as (values
('t01-i10',1.75),
('t02-i05',1.25),
('t07-i02',0.3),
('t08-i01',0.3),
('t08-i02',0.35),
('t08-i04',0.35),
('t09-i04',2.75),
('t09-i05',3.5),
('t13-i01',3.0),
('t13-i02',6.0),
('t01-i03',2.25),
('t02-i02',4.0),
('t03-i03',6.0),
('t04-i09',18),
('t10-i01',1100),
('t10-i04',7),
('t11-i08',60))
, h as (insert into public.catalog_rate_history (item_id,old_rate,new_rate,changed_by,reason)
  select c.item_id,i.rate,c.new_rate,'Nestor (via Claude)','2026-11-12 modelo minutos×tarifa: labor no cubría el rate (hist. Cotto + benchmarks)' from c join public.catalog_items i on i.id=c.item_id returning 1)
update public.catalog_items i set rate=c.new_rate from c where i.id=c.item_id;
