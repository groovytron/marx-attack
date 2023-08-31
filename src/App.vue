<script lang="ts">
import { defineComponent } from 'vue';
import Gun, { IGunChain, IGunInstance } from 'gun';
import { MUSIC_GENRES } from './constants/music-genres';
import { GUN_RELAY_HOSTS } from './constants/gun-relay-hosts';
import {
  Chart as ChartJS,
  Colors,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale
} from 'chart.js'
import { Bar } from 'vue-chartjs'
import { BehaviorSubject } from 'rxjs';
import { bufferTime, filter } from 'rxjs/operators';
import Fireworks from '@fireworks-js/vue';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend, Colors);

interface GenreSuggestion {
  add: string|null;
  remove: string|null;
}

interface GenreMajorityEvent {
  genre: string;
  maximum: number;
}

const EVENT = import.meta.env.VITE_EVENT_NAME;
const LOCAL_STORAGE_KEY = 'genre';
const LANG_STORAGE_KEY = 'lang';
const CHART_UPDATE_DELAY = 500;
const SECONDS_TO_MILLISECONDS = 1000;
const MAJORITY_UPDATE_DELAY = 15;
const FIREWORKS_DURATION = 5;
const WHITE = '#fff';
const LABELS_FONT_SIZE = 14;
const CHART_COLOR = import.meta.env.VITE_CHART_COLOR;

export default defineComponent({
  components: {
    Bar,
    Fireworks
  },
  watch: {
    '$i18n.locale': (newValue: string) => {
      localStorage.setItem(LANG_STORAGE_KEY, newValue);
    }
  },
  computed: {
    options() {
      return {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false,
          },
          title: {
            display: true,
            text: this.$t('chartTitle'),
            color:  CHART_COLOR,
            font: {
              size: 51.2,
            }
          },
        },
        scales: {
          x: {
            border: {
              color: WHITE,
            },
            ticks: {
              color: WHITE,
              font: {
                size: LABELS_FONT_SIZE,
              },
            },
          },
          y: {
            border: {
              color: WHITE,
            },
            title: {
              display: true,
              text: this.$t('votes'),
              color: WHITE,
              font: {
                size: LABELS_FONT_SIZE,
              },
            },
            min: 0,
            ticks: {
              stepSize: 1,
              color: WHITE,
              font: {
                size: LABELS_FONT_SIZE,
              },
            }
          }
        }
      };
    }
  },
  data() {
    return {
      languages: ['fr', 'de', 'en'],
      languagesMap: new Map<string, string>([
        ['fr', 'Français'],
        ['de', 'Deutsch'],
        ['en', 'English']
      ]),
      adminModeIsEnabled: import.meta.env.VITE_ADMIN_MODE === "true",
      musicGenres: MUSIC_GENRES,
      gun: {} as IGunInstance<any>,
      gunStats: {} as IGunChain<any>,
      genreStats: new Map<string, number>(),
      previousChanges: new Array<string>(),
      previousGenre: null as string|null,
      votesChanges: new BehaviorSubject<GenreSuggestion|null>(null),
      majorityGenre: '',
      liveMajority: '',
      majorityChanged: new BehaviorSubject<GenreMajorityEvent>({genre: '', maximum: 0}),
      fireworksOptions: { opacity: 0.5 },
      data: {
        labels: [] as string[],
        datasets: [] as any[]
      } as any,
    };
  },
  mounted() {
    const lang = localStorage.getItem(LANG_STORAGE_KEY);

    if (lang !== null && this.languages.includes(lang)) {
      this.$root!.$i18n.locale = lang;
    }

    this.previousGenre = localStorage.getItem(LOCAL_STORAGE_KEY) ?? null;

    this.gun = Gun(GUN_RELAY_HOSTS);

    this.gunStats = this.gun.get(EVENT);

    this.resetStats();

    this.votesChanges.pipe(
      bufferTime(CHART_UPDATE_DELAY)
    ).subscribe(() => {
      this.updateChartConfig();
      this.computeMajority();
    });

    this.majorityChanged.pipe(
      filter(() => this.$refs.fireworks !== null),
      filter(e => e.genre !== this.majorityGenre),
      bufferTime(MAJORITY_UPDATE_DELAY * SECONDS_TO_MILLISECONDS),
      filter(e => e.length > 0),
    ).subscribe((majorities: GenreMajorityEvent[]) => {
      const majority = majorities.pop() as GenreMajorityEvent;

      this.majorityGenre = majority.genre;

      const fireworks = this.$refs.fireworks as typeof Fireworks;

      if (fireworks === null) {
        return;
      }

      fireworks.start();

      setTimeout(() => fireworks.stop(), FIREWORKS_DURATION * SECONDS_TO_MILLISECONDS);
    });

    this.gunStats.map().on((data: GenreSuggestion|null, id: string) => {
      // Eliminate double events
      if (this.previousChanges.includes(id)) {
        return;
      }

      this.votesChanges.next(data);

      this.previousChanges.push(id);

      if (data === null) {
        this.resetStatsAndVote();
        this.votesChanges.next(data);

        return;
      }

      if (data.add) {
        this.genreStats.set(data.add, (this.genreStats.get(data.add) ?? 0) + 1);
      }

      if (data.remove) {
        const result = this.genreStats.get(data.remove);

        if (result !== undefined && result !== 0) {
          this.genreStats.set(data.remove, Math.max(result - 1, 0));
        }
      }
    });
  },
  methods: {
    suggestGenre(genre: string|null) {
      const previousGenre = localStorage.getItem(LOCAL_STORAGE_KEY);

      if (genre === null) {
        if (previousGenre !== null) {
          this.gunStats.set({add: null, remove: previousGenre});
        }

        localStorage.removeItem(LOCAL_STORAGE_KEY);
        this.previousGenre = genre;

        return;
      }

      this.gunStats.set({add: genre, remove: previousGenre});

      localStorage.setItem(LOCAL_STORAGE_KEY, genre);
      this.previousGenre = genre;
    },
    resetStatsAndVote() {
      this.resetStats();
    },
    resetStats() {
      this.musicGenres.forEach((genreItem: string) => this.genreStats.set(genreItem, 0));
    },
    resetVotes() {
      this.gunStats.set(null as any);
    },
    updateChartConfig() {
      this.data = {
        labels: Array.from(this.genreStats.keys()),
        datasets: [
          {
            label: 'Votes',
            data: Array.from(this.genreStats.values()),
            backgroundColor: CHART_COLOR,
            color: WHITE,
          }
        ]
      };
    },
    computeMajority() {
      const maximum = Math.max(...Array.from(this.genreStats.values()));
      const maximumEntries = Array.from(this.genreStats.entries()).filter((item: [string, number]) => item[1] === maximum);

      if (maximumEntries.length === 0 || maximumEntries.length > 1) {
        this.liveMajority = '';
        return;
      }

      if (maximumEntries.length === 1) {
        const genre = maximumEntries[0][0];

        this.liveMajority = genre;

        this.majorityChanged.next({
          genre,
          maximum
        });
      }
    }
  }
})
</script>

<template>
  <div class="content">
    <div id="image-container">
      <img id="marx-picture" src="/karl_marx_laser_multiple.webp">
    </div>
    <div id="language-buttons">
      <button v-for="(lang, i) in languages" :key="`Lang${i}`" @click="$root!.$i18n.locale = lang" :disabled="$i18n.locale.split('-')[0] === lang">
        {{ languagesMap.get(lang) }}
      </button>
    </div>
    <h1 id="title">
      Marx Attack
    </h1>
    <p id="subtitle">
      {{ $t('subtitle') }}
    </p>
    <div id="canvas-container">
      <Bar :data="data" :options="options" />
    </div>
    <h2 id="vote-heading">{{ $t('yourVote') }}</h2>
    <div>
      <button v-for="genreItem in musicGenres" :key="genreItem" @click="suggestGenre(genreItem)" :disabled="previousGenre === genreItem">
        {{ genreItem }}
      </button>
      <button @click="suggestGenre(null)" :disabled="previousGenre === null">
        {{ $t('abstain') }}
      </button>
      <h3 v-if="liveMajority !== ''">
        {{ $t('majority') }}: <span id="live-majority">{{ liveMajority }}</span>
      </h3>
      <p v-html="$t('lost')">
      </p>
    </div>
    <div v-if="adminModeIsEnabled === true">
      <h2>
        Danger zone
      </h2>
      <button @click="resetVotes()">
        {{ $t('resetVotes') }}
      </button>
    </div>
    <p id="instructions">
      {{ $t('instructions.first') }}
    </p>
    <p>
      <b>{{ $t('instructions.second') }}</b>
    </p>
    <p v-html="$t('backToVotes')">
    </p>
    <p id="footer">
      Made with ♥️ by
      <a href="https://github.com/groovytron" target="_blank">groovytron</a> in
      Switzerland
    </p>
  </div>
  <Fireworks
    ref="fireworks"
    :autostart="false"
    :options="fireworksOptions"
    :style="{
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      position: 'fixed',
    }"
  />
</template>

<style scoped>
  .content {
    z-index: 1;
    position: absolute;
    left: 2em;
    top: 2em;
    right: 2em;

    * {
      position: static;
    }
  }

  #title {
    margin-top: 0;
    margin-bottom: 0;
  }

  #language-buttons {
    margin-top: 0.75em;
  }

  #subtitle {
    color: #caa81a;
    margin-top: 0;
  }

  #image-container, #marx-picture {
    max-width: 100%;
    height: 30vh;
  }

  #canvas-container {
    height: 50vh;
    width: 100%;
  }

  #vote-heading {
    margin-top: 0.125em;
    margin-bottom: 0.125em;
  }

  #live-majority {
    color: #caa81a;
  }

  button:not(:first-child) {
    margin-left: 0.5em;
  }

  button {
    margin-top: 0.25em;
  }

  #footer {
    text-align: center;
    font-size: 1em;
  }
</style>
