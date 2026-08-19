interface Step {
  number: number;
  label: string;
}

interface StepIndicatorProps {
  steps: Step[];
  currentStep: number;
}

const StepIndicator = ({ steps, currentStep }: StepIndicatorProps) => {
  return (
    <div className="w-full mb-8">
      {/* Desktop: horizontal with labels */}
      <div className="hidden sm:flex items-center justify-center">
        {steps.map((step, index) => (
          <div key={step.number} className="flex items-center">
            {/* Step bubble */}
            <div className="flex flex-col items-center">
              <div
                className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm
                  transition-all duration-300
                  ${currentStep > step.number
                    ? 'bg-brand-600 text-white shadow-btn'
                    : currentStep === step.number
                      ? 'bg-brand-600 text-white shadow-btn ring-4 ring-brand-100'
                      : 'bg-gray-100 text-gray-400 border-2 border-gray-200'
                  }`}
              >
                {currentStep > step.number ? (
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  step.number
                )}
              </div>
              <span
                className={`mt-2 text-xs font-medium whitespace-nowrap
                  ${currentStep >= step.number ? 'text-brand-600' : 'text-gray-400'}`}
              >
                {step.label}
              </span>
            </div>

            {/* Connector line */}
            {index < steps.length - 1 && (
              <div
                className={`h-0.5 w-16 lg:w-24 mx-2 mb-5 transition-all duration-300
                  ${currentStep > step.number ? 'bg-brand-600' : 'bg-gray-200'}`}
              />
            )}
          </div>
        ))}
      </div>

      {/* Mobile: compact progress */}
      <div className="flex sm:hidden items-center gap-3">
        <div className="flex gap-1.5 flex-1">
          {steps.map(step => (
            <div
              key={step.number}
              className={`h-1.5 flex-1 rounded-full transition-all duration-300
                ${currentStep > step.number
                  ? 'bg-brand-600'
                  : currentStep === step.number
                    ? 'bg-brand-400'
                    : 'bg-gray-200'
                }`}
            />
          ))}
        </div>
        <span className="text-sm font-medium text-gray-500 whitespace-nowrap">
          Step {currentStep}/{steps.length}
        </span>
      </div>

      {/* Mobile: current step label */}
      <div className="flex sm:hidden mt-2">
        <span className="text-sm font-semibold text-brand-600">
          {steps.find(s => s.number === currentStep)?.label}
        </span>
      </div>
    </div>
  );
};

export default StepIndicator;
