package tlang;

import io.cucumber.junit.CucumberOptions;
import io.cucumber.junit.Cucumber;
import org.junit.runner.RunWith;


@RunWith(Cucumber.class)
@CucumberOptions( features = "src/test/resources/tlang/Features/Spec Features"
                , plugin = {"progress", "html:build/reports/tests/cucumber/html"}
                )
public class TestAllCucumberFeatures {
}
