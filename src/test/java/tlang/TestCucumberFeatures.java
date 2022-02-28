package tlang;

import io.cucumber.junit.CucumberOptions;
import io.cucumber.junit.Cucumber;
import org.junit.runner.RunWith;


@RunWith(Cucumber.class)
@CucumberOptions( features = "src/test/resources/tlang/"
             // , tags = "@SmokeTest"
             // , tags = "@InProgress"
                , tags = "@testthis"
                , plugin = {"progress"
                        // , "html:build/reports/tests/cucumber/html/"             // Cuke 5.x
                        // , "html:build/reports/tests/cucumber/CucumberTest.html" // Cuke 6+
                           , "html:build/reports/tests/cucumber/FeaturesInProgress.html"
                           }
                )
public class TestCucumberFeatures {
}
