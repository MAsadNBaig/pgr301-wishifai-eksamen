
package no.pgr301.exam.service;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.rekognition.RekognitionClient;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsRequest;
import software.amazon.awssdk.services.rekognition.model.DetectLabelsResponse;
import software.amazon.awssdk.services.rekognition.model.Image;
import software.amazon.awssdk.services.rekognition.model.Label;

import java.util.List;

@Service
public class RekognitionService {

    private final RekognitionClient client;
    private final MeterRegistry meterRegistry;

    public RekognitionService(RekognitionClient client, MeterRegistry meterRegistry) {
        this.client = client;
        this.meterRegistry = meterRegistry;
    }

    public List<String> detectLabels(byte[] bytes) {
        return Timer.builder("wishifai.rekognition.duration")
                .description("Time taken by Amazon Rekognition to detect image labels")
                .register(meterRegistry)
                .record(() -> {
                    DetectLabelsResponse resp = client.detectLabels(DetectLabelsRequest.builder()
                            .image(Image.builder().bytes(SdkBytes.fromByteArray(bytes)).build())
                            .maxLabels(20)
                            .minConfidence(70f)
                            .build());

                    return resp.labels().stream().map(Label::name).toList();
                });
    }
}
