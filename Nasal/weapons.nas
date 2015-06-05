var masterarm = "controls/armament/master-arm";
var gun0 = "controls/armament/gun[0]/fire";

var tracergun0 = "controls/armament/gun[0]/tracer";
var tracerevery = 20;
		var times0 = 49;
var statgun0 = "controls/armament/gun[0]/serviceable";

var drop_bomb = func {
 if (getprop("/controls/armament/master-arm") == 1)  {
	#print(getprop("/sim/weight[0]/selected"));
  if(getprop("/sim/weight[0]/selected") == "SC250 Bomb"){
     setprop("/controls/armament/station/release-all", 1);
     setprop("/sim/weight[0]/type",0);
     setprop("/sim/weight[0]/selected","none");
     setprop("/sim/weight[0]/weight-lb",0);
     } 
  if(getprop("/sim/weight[0]/selected") == "BC250 Bomb"){
     setprop("/controls/armament/station/release-all", 1);
     setprop("/sim/weight[0]/type",1);
     setprop("/sim/weight[0]/selected","none");
     setprop("/sim/weight[0]/weight-lb",0);
     } 
  if(getprop("/sim/weight[0]/selected") == "NC250 Bomb"){
     setprop("/controls/armament/station/release-all", 1);
     setprop("/sim/weight[0]/type",2);
     setprop("/sim/weight[0]/selected","none");
     setprop("/sim/weight[0]/weight-lb",0);
     } 
	}
}

setlistener("/controls/armament/trigger", func(n) {
    var stat = n.getValue();
		if 	( stat ) {
				if ( getprop(masterarm) )  {
						if ( getprop(statgun0) == 1) {
								setprop(gun0,1);
							#	print (getprop("ai/submodels/submodel[0]/count"));
						}

				}
     } else {
				setprop(gun0, 0 );

			}
});

setlistener("/controls/armament/trigger1", func(n) {
    var stat = n.getValue();
		if 	( stat ) {
				if ( masterarm.getValue() )  {
						if (statcannon0.getValue() == 1) {
								cannon0.setValue (1);
						}
						if (statcannon1.getValue() == 1) {
								cannon1.setValue (1);
						}
				}
     } else {
				cannon0.setValue (0);
				cannon1.setValue (0);
			}
});



setlistener("sim/model/aircraft/impact/gun", func(n) {
    var impact = n.getValue();
    var solid = getprop(impact ~ "/material/solid");
    
    if (solid) {
#      var long = getprop(impact ~ "/impact/longitude-deg");    
#      var lat = getprop(impact ~ "/impact/latitude-deg");
			setprop("sim/model/aircraft/impact/splash",0);
    }
		else {
			setprop("sim/model/aircraft/impact/splash",1);
		}
  });

  setlistener("ai/models/model-impact", func(n) {
    var impact = n.getValue();
    var solid = getprop(impact ~ "/material/solid");
    
    if (solid)
    {
      var long = getprop(impact ~ "/impact/longitude-deg");    
      var lat = getprop(impact ~ "/impact/latitude-deg");
			var type = getprop("sim/weight[0]/type");
			var fused = getprop ("controls/armament/station[0]/fuse-type");
			var timer = 0.0;
					print (fused);
					if ( fused !=2 ) {
							print ("armed ");
							if ( fused == 1 or fused == 3) {
									timer = 10.0;
									print ("timed with ",timer);
							}
							if (type == 0) {
		     					settimer (func {geo.put_model( "Aircraft/bf109/Models/Effects/crater.ac", lat, long )}, timer);
							}
							if (type == 1) {
				     			settimer (func {geo.put_model( "Models/Effects/Wildfire/wildfire.xml", lat, long )}, timer);
							}
							if (type == 2) {
				     			settimer (func {geo.put_model( "Aircraft/bf109/Models/Effects/smokebomb.xml", lat, long )}, timer);
							}
					}
    }
  });
