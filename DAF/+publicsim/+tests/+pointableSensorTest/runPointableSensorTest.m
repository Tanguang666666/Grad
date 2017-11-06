
xlsFile='./+publicsim/+tests/+pointableSensorTest/pointableSensorTest.xlsx';
xm=publicsim.models.excelBased.excelModelBuilder(xlsFile);
%Do any agent manip here:
%xm.simInst

xm.run();

%Post Processing
log=xm.getLogger();
positionProcessor = publicsim.analysis.basic.Movement(log);
positionProcessor.plotOnEarth(xm.simEarth);

sensorProcessor = publicsim.analysis.functional.Sensing(log);
sensorProcessor.plotObservations();
out = sensorProcessor.getObservationsBySensor();
