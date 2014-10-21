function id = getSplitDataHash( setup )

id = DataHash( {getLabelsHash( setup ) getFeaturesHash( setup ) setup.generalizationEstimation } );
