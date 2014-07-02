function id = getSplitDataHash( niState )

id = DataHash( {getLabelsHash( niState ) getFeaturesHash( niState ) niState.generalizationEstimation } );
