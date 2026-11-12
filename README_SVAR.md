# PGR301 Eksamen 2026 – Wishifai

**Kandidatnummer: 48**

## Oppgave 1 – Docker og CI/CD

### Docker

Applikasjonen pakkes med en multi-stage Dockerfile og kjører Spring Boot på port 8080.

Bygg Docker-imaget:

```bash
docker build -t wishifai:local .
```

Start containeren på localhost:9999:

```bash
docker run --rm -p 9999:8080 \
  -v ~/.aws:/root/.aws:ro \
  -e AWS_REGION=eu-west-1 \
  -e S3_BUCKET=wishifai-48-images-244530008913 \
  wishifai:local
```

AWS-konfigurasjonen monteres skrivebeskyttet fra vertsmaskinen. AWS-nøkler bygges ikke inn i Docker-imaget.

### GitHub Actions

Workflowen ligger i `.github/workflows/ci.yml` og kjører ved push til `main`.

Pipeline består av to jobber:

1. `build-and-push` bygger Docker-imaget og publiserer det til Amazon ECR.
2. `terraform` kontrollerer formatering, initialiserer Terraform og anvender infrastrukturen.

AWS-legitimasjon lagres som GitHub Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` og `AWS_REGION`.

Imaget tagges med `${{ github.sha }}`. Dette gir hvert bygg en unik tag knyttet til Git-commiten. Dermed kan vi identifisere hvilken versjon som er distribuert, og unngår at `latest` overskriver sporbarheten.

Terraform-jobben bruker `needs: build-and-push` fordi infrastrukturen skal distribuere imaget som nettopp er bygget og publisert. Hvis jobbene kjørte parallelt, kunne Terraform forsøkt å distribuere et image som ennå ikke finnes i ECR.

GitHub Actions:
https://github.com/MAsadNBaig/pgr301-wishifai-eksamen/actions/runs/43200746912

## Oppgave 2 – ECS Express og Terraform

Terraform-konfigurasjonen ligger i `infra/`.

Den oppretter og konfigurerer:

- ECS Express-service: `wishifai-48`
- S3-bøtte for opplastede bilder: `wishifai-48-images-244530008913`
- Kandidatspesifikk IAM task role: `wishifai-task-role-48`
- Tillatelser for S3, Rekognition, Bedrock og CloudWatch.

Eksisterende ECS execution role og infrastructure role gjenbrukes. S3-bøtten har blokkering av offentlig tilgang og kryptering aktivert.

Applikasjonen mottar blant annet `AWS_REGION` og `S3_BUCKET` som miljøvariabler fra ECS.

Terraform state lagres sentralt i S3:

- Bucket: `pgr301-terraform-state`
- Region: `eu-west-1`
- State key: `wishifai/48/terraform.tfstate`

**Applikasjonens offentlige URL:**

https://wi-288c1d76286349018ae86bc912585c8b.ecs.eu-west-1.on.aws

## Oppgave 3 – Observability

Micrometer brukes til å samle applikasjonsmålinger, med Amazon CloudWatch som observability-backend og namespace `Wishifai`.

Tre sentrale målinger er implementert:

- `wishifai.rekognition.duration`: måler tiden Rekognition bruker på bildegjenkjenning.
- `wishifai.bedrock.duration`: måler tiden Bedrock bruker på generering av anbefalinger.
- `wishifai.gifts.generated`: teller genererte gaveforslag.

Terraform oppretter CloudWatch-dashboardet `wishifai-48-observability` og alarmen `wishifai-48-rekognition-slow`.

Dashboardet viser infrastrukturmålinger fra ECS, blant annet CPU, minne og antall kjørende tasks. Det er også konfigurert paneler for applikasjonsmålinger fra Micrometer, JVM, HTTP-responstid og garbage collection.

Alarmen overvåker gjennomsnittlig Rekognition-latens (`wishifai.rekognition.latency.avg`) med en terskel på 5000 ms.

Dashboardet og alarmen er opprettet gjennom Terraform. Applikasjonens egendefinerte målinger er implementert, men alle måleverdiene ble ikke verifisert som synlige i CloudWatch under testing.

## Refleksjon – GenAI og DevOps

Generativ kunstig intelligens kan gjøre utvikling og drift mer effektiv, men introduserer også utfordringer som må håndteres gjennom gode DevOps-prinsipper.

En viktig utfordring er at generative modeller ikke alltid gir samme resultat for samme input. I Wishifai brukes Amazon Bedrock til å generere gaveforslag basert på bilder og informasjon fra Rekognition. Resultatet kan variere, og modellen kan produsere forslag som er irrelevante eller feil. Derfor bør applikasjonen testes med et representativt datasett av bilder og forventede resultater. Evalueringen bør ikke bare kontrollere om API-et svarer, men også om forslagene faktisk er relevante og nyttige.

Modell- og promptversjoner bør behandles som deler av applikasjonens versjonering. Når en prompt eller modell endres, bør endringen testes før produksjonssetting. En kontrollert utrulling, for eksempel med canary deployment eller feature flags, kan redusere risikoen. Dersom kvaliteten blir dårligere, bør det være mulig å gå tilbake til en tidligere modell- eller promptversjon.

Observability blir spesielt viktig i generative AI-systemer. I tillegg til vanlige tekniske målinger bør man overvåke responstid, feilrate, tokenforbruk og kostnader. Kvaliteten på modellresultatene bør også evalueres over tid, siden modelloppdateringer og endringer i brukerinput kan påvirke resultatene.

Sikkerhet og personvern må inngå i hele utviklingsprosessen. Bilder og brukerdata bør behandles med minst mulige rettigheter, og hemmeligheter må lagres i sikre løsninger som GitHub Secrets og AWS IAM. Modellen bør heller ikke få mer tilgang enn den trenger.

Menneskelig kontroll kan være nødvendig når konsekvensene av feil er store. Wishifai gir gaveforslag, og risikoen er derfor relativt begrenset. I systemer som brukes innen helse, jus eller økonomi, må kravene til validering, dokumentasjon og menneskelig godkjenning være strengere.

Generativ AI bør dermed ikke behandles som en erstatning for testing og kvalitetssikring. Den bør integreres i en DevOps-prosess med automatiserte tester, versjonskontroll, overvåking, sikkerhet og mulighet for rask tilbakeføring.
Regelmessig evaluering og dokumentasjon gjør det enklere å oppdage problemer tidlig og sikre stabil drift over tid.
