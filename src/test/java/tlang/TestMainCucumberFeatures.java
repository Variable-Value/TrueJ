package tlang;

import io.cucumber.junit.CucumberOptions;
import io.cucumber.junit.Cucumber;
import org.junit.runner.RunWith;


@RunWith(Cucumber.class)
@CucumberOptions( features = "src/test/resources/tlang/Features/A - Spec Features"
                , plugin = {"progress"
                        // , "html:build/reports/tests/cucumber/html/"             // Cuke 5.x
                           , "html:build/reports/tests/cucumber/CucumberTest.html" // Cuke 6+
                           }
                )
public class TestMainCucumberFeatures {
}
